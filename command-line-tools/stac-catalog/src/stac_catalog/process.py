from pathlib import Path
from pystac.extensions.raster import (
        RasterBand,
        Statistics,
        DataType,
    )
from pystac.extensions.render import RenderExtension, Render


def _import_runtime_dependencies():
    import numpy as np
    import pystac
    import rasterio
    from rasterio.enums import Resampling
    from rasterio.shutil import copy as rio_copy
    from rasterio.windows import Window, from_bounds
    from rasterio.windows import bounds as window_bounds
    from rasterio.windows import transform as window_transform

    return {
        "np": np,
        "pystac": pystac,
        "rasterio": rasterio,
        "Resampling": Resampling,
        "Window": Window,
        "from_bounds": from_bounds,
        "rio_copy": rio_copy,
        "window_bounds": window_bounds,
        "window_transform": window_transform,
    }


def rasterio_save_cog_bbox(input_tif: Path, output_tif: Path, bbox=None):
    deps = _import_runtime_dependencies()
    np = deps["np"]
    rasterio = deps["rasterio"]
    Resampling = deps["Resampling"]
    Window = deps["Window"]
    from_bounds = deps["from_bounds"]
    rio_copy = deps["rio_copy"]
    window_bounds = deps["window_bounds"]
    window_transform = deps["window_transform"]

    factors = [2, 4, 8, 16, 32, 64]

    with rasterio.open(input_tif) as src:
        profile = src.profile.copy()

        if bbox is not None:
            minx, miny, maxx, maxy = bbox
            win = from_bounds(minx, miny, maxx, maxy, transform=src.transform)
            win = win.round_offsets().round_lengths()
            win = win.intersection(Window(0, 0, src.width, src.height))

            if win.width <= 0 or win.height <= 0:
                raise ValueError(
                    "BBOX does not intersect raster extent (empty window)."
                )

            out_bounds = window_bounds(win, src.transform)
            arr = src.read(window=win)
            new_transform = window_transform(win, src.transform)

            profile.update(
                height=int(win.height),
                width=int(win.width),
                transform=new_transform,
            )
        else:
            arr = src.read()
            out_bounds = src.bounds

    if np.issubdtype(arr.dtype, np.floating):
        nan_mask = np.isnan(arr)
        if nan_mask.any():
            arr = arr.copy()
            arr[nan_mask] = 0

    profile.update(
        driver="GTiff",
        tiled=True,
        blockxsize=256,
        blockysize=256,
        compress="deflate",
        BIGTIFF="IF_NEEDED",
        count=arr.shape[0],
    )

    tmp = Path("/tmp") / f"{output_tif.stem}_temp.tif"
    tmp.parent.mkdir(parents=True, exist_ok=True)

    try:
        with rasterio.open(tmp, "w", **profile) as dst:
            dst.write(arr)
            dst.build_overviews(factors, Resampling.nearest)
            dst.update_tags(ns="rio_overview", resampling="nearest")

        rio_copy(
            str(tmp),
            str(output_tif),
            copy_src_overviews=True,
            driver="COG",
            compress="deflate",
        )
    finally:
        if tmp.exists():
            tmp.unlink()

    return out_bounds


def build_stac_catalog(input_dir: Path, reference_id: str, bbox=None) -> Path:
    deps = _import_runtime_dependencies()
    pystac = deps["pystac"]

    catalog_path = input_dir / "catalog.json"
    if not catalog_path.exists():
        raise FileNotFoundError(f"Missing catalog.json at: {catalog_path}")

    catalog = pystac.Catalog.from_file(str(catalog_path))
    item_links = [link for link in catalog.links if link.rel == "item"]
    if len(item_links) != 1:
        raise ValueError(
            f"Expected exactly 1 item link in catalog, found {len(item_links)}"
        )

    item_json_path = (catalog_path.parent / Path(item_links[0].href)).resolve()
    if not item_json_path.exists():
        raise FileNotFoundError(f"Item JSON not found at: {item_json_path}")

    item = pystac.Item.from_file(str(item_json_path))
    asset_tif = item.get_assets().get("TIFF")
    if asset_tif is None:
        raise KeyError("Expected a TIFF asset with key 'TIFF' in the input STAC item.")

    tif_path = item_json_path.parent / Path(asset_tif.href)
    if not tif_path.exists():
        raise FileNotFoundError(f"TIFF asset path does not exist: {tif_path}")

    bundle_name = f"{reference_id}-COG"
    out_root = Path.cwd().resolve() / bundle_name
    out_item_dir = out_root / bundle_name
    out_item_json_path = out_item_dir / f"{bundle_name}.json"
    out_cog_path = out_item_dir / "ost-ard-cog.tif"
    out_catalog_path = out_root / "catalog.json"

    out_item_dir.mkdir(parents=True, exist_ok=True)
    out_bounds = rasterio_save_cog_bbox(tif_path, out_cog_path, bbox=bbox)

    out_item = item.clone()
    out_item.id = bundle_name
    out_item.set_self_href(str(out_item_json_path))
    out_item.assets = {}

    # Make sure the Item advertises the extensions we are about to use.
    for ext in [
        "https://stac-extensions.github.io/raster/v1.1.0/schema.json",
        "https://stac-extensions.github.io/render/v2.0.0/schema.json",
    ]:
        if ext not in out_item.stac_extensions:
            out_item.stac_extensions.append(ext)

    # Define asset and raster:bands in it
    out_asset = pystac.Asset(
        href=out_cog_path.name,
        media_type="image/tiff; application=geotiff; profile=cloud-optimized",
        title="OST-processed ARD COG",
        description=(
            "OST ARD raster with 3 bands - (1) co-pol backscatter (dB), (2) cross-pol backscatter (dB), (3) derived co/cross ratio"
        ),
        roles=["data", "visual"],
    )

    # Add asset to item 
    out_item.add_asset("ost-ard-cog", out_asset)

    minx, miny, maxx, maxy = map(float, out_bounds)
    out_item.bbox = [minx, miny, maxx, maxy]
    out_item.geometry = {
        "type": "Polygon",
        "coordinates": [
            [
                [minx, miny],
                [minx, maxy],
                [maxx, maxy],
                [maxx, miny],
                [minx, miny],
            ]
        ],
    }

    # ---------------------------
    # Add renders to the Item. Note that PySTAC Render.create supports standard render fields, but not bidx.
    # For a single multiband asset, add bidx manually for eg TiTiler/rio-tiler-style clients.
    
    # Define rescale ranges
    rescale_copol = [-20, 0] # based on standard co-polarised VV-HH ranges  
    rescale_crosspol = [-26, -5] # based on standard cross-polarised VH-HV ranges  
    rescale_ratio = [2, 12] # based on 5% - 95% percentile of the sampled S1 scene
    
    ost_sar_rgb = Render.create(
        assets=["ost-ard-cog"],
        title="OST SAR RGB composite",
        rescale=[rescale_copol, rescale_crosspol, rescale_ratio],
        nodata=0,
        resampling="nearest",
    )
    ost_sar_rgb.properties["bidx"] = [1, 2, 3]

    copol_mono = Render.create(
        assets=["ost-ard-cog"],
        title="Co-polarisation backscatter (dB)",
        rescale=[rescale_copol],
        nodata=0,
        colormap_name="grayscale",
        resampling="nearest",
    )
    copol_mono.properties["bidx"] = [1]

    crosspol_mono = Render.create(
        assets=["ost-ard-cog"],
        title="Cross-polarisation backscatter (dB)",
        rescale=[rescale_crosspol],
        nodata=0,
        colormap_name="grayscale",
        resampling="nearest",
    )
    crosspol_mono.properties["bidx"] = [2]

    ratio_mono = Render.create(
        assets=["ost-ard-cog"],
        title="Co/Cross ratio",
        rescale=[rescale_ratio],
        nodata=0,
        colormap_name="grayscale",
        resampling="nearest",
    )
    ratio_mono.properties["bidx"] = [3]

    RenderExtension.ext(out_item, add_if_missing=True).apply(
        renders={
            "ost_sar_rgb": ost_sar_rgb,
            "copol_mono": copol_mono,
            "crosspol_mono": crosspol_mono,
            "ratio_mono": ratio_mono,
        }
    )

    out_catalog = pystac.Catalog(
        id="ost-ard-cog-catalog",
        description="OST ARD COG output",
    )
    out_catalog.set_self_href(str(out_catalog_path))
    out_catalog.add_item(out_item)
    out_catalog.save(catalog_type=pystac.CatalogType.SELF_CONTAINED)

    return out_root
