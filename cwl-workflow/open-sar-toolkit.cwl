cwlVersion: v1.2
$namespaces:
  s: https://schema.org/

schemas:
- http://schema.org/version/9.0/schemaorg-current-http.rdf


s:name: My shiny workflow
s:description: There's no workflow on earth like this one that solves NP-complete problems.
s:dateCreated: '2026-01-01'
s:license:
  '@type': s:CreativeWork
  s:identifier: CC-BY-4.0

s:operatingSystem:
- Linux
- macOS
s:softwareRequirements:
- https://cwltool.readthedocs.io/en/latest/
- https://www.python.org/

s:softwareVersion: 2.1.7
s:softwareHelp:
- '@type': s:CreativeWork
  s:name: User Manual
  s:url: https://meoga-shiny-workflow.readthedocs.io/en/latest/
- '@type': s:CreativeWork
  s:name: Admin Manual
  s:url: https://meoga.io/meoga/shiny-workflow/admin


s:publisher:
  '@type': s:Organization
  s:name: Make Earth Observation Great Again
  s:email: info@meoga.com
  s:identifier: https://ror.org/9999cx000

s:author:
- '@type': s:Person
  s:givenName: Lex
  s:familyName: Luthor
  s:email: lex.luthor@luthorcorp.com
  s:identifier: https://orcid.org/0000-9999-0000-9999
  s:affiliation:
    '@type': s:Organization
    s:name: Luthor Corp
    s:identifier: https://ror.org/0000cx000

s:contributor:
- '@type': s:Person
  s:givenName: Clark
  s:familyName: Kent
  s:email: clark.kent@dailyplanet.com
  s:identifier: https://orcid.org/0000-9999-0000-9999
  s:affiliation:
    '@type': s:Organization
    s:name: Daily Planet
    s:identifier: https://ror.org/0000cx000

$graph:
  - label: OpenSarToolkit
    class: Workflow
    doc: Preprocessing an S1 image with OST
    id: opensartoolkit
    requirements: 
      NetworkAccess:
        networkAccess: true
      ScatterFeatureRequirement: {}
      SubworkflowFeatureRequirement: {}
      StepInputExpressionRequirement: {}
      InlineJavascriptRequirement: {}
      SchemaDefRequirement:
        types:
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/ogc.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/experimental/api-endpoint.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/experimental/discovery.yaml
    inputs:
      resolution:
        type: int
        label: Resolution
        doc: Resolution in metres
      ard-type:
        label: ARD type
        doc: Type of analysis-ready data to produce
        type:
        - symbols:
          - OST_GTC
          - OST-RTC
          - CEOS
          - Earth-Engine
          type: enum
      with-speckle-filter:
        label: Speckle filter
        doc: Whether to apply a speckle filter
        type:
        - symbols:
          - APPLY-FILTER
          - NO-FILTER
          type: enum
      resampling-method:
        label: Resampling method
        doc: Resampling method to use
        type:
        - symbols:
          - BILINEAR_INTERPOLATION
          - BICUBIC_INTERPOLATION
          type: enum
      target_datetime:
        label: Target datetime
        doc: Target datetime in ISO 8601 format
        type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#DateTime
      bbox:
        label: Area of interest
        doc: AOI polygon (bbox field will be used for STAC bbox)
        type: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml#Polygon
    outputs:
      output:
        outputSource: 
          - s1_subworkflow/ost_ard_cog
        type: 
          type: array
          items: Directory
    steps:
      build_search_request:
        run: "#build_search_request"
        label: Build search_request and add datetime-interval
        in:
          target_datetime: target_datetime
          bbox: bbox
        out: [search_request_norm]
      discovery:
        label: OData API discovery
        doc: Discover STAC items from a OData API endpoint based on a search request
        in:
          api_endpoint:
            valueFrom: |
              ${
                return {
                  headers: [],
                  url: { value: "https://catalogue.dataspace.copernicus.eu/odata/v1/Products" }
                };
              }
          search_request: build_search_request/search_request_norm
        run: "https://github.com/eoap/schemas/releases/download/0.3.0/odata-client.0.3.0.cwl"
        out:
          - search_output
      convert_search:
        run: "#convert-search"
        label: Convert Search
        doc: Convert Search results to get the item self hrefs  
        in:
          search_results: discovery/search_output
          target_datetime: target_datetime
        out: [items]
      s1_subworkflow:
        run: "#s1_subworkflow"
        label: Sub-workflow to process searched S1 data
        doc: Sub-workflow to process searched S1 data
        scatter: reference_ID
        in:
          reference_ID: convert_search/items
          bbox:
            source: bbox
            valueFrom: $(self.bbox)
          resolution: resolution
          ard-type: ard-type
          with-speckle-filter: with-speckle-filter
          resampling-method: resampling-method
        out: [ost_ard_cog]
        
# =====================================
 
  - id: build_search_request
    class: ExpressionTool
    requirements: 
      NetworkAccess:
        networkAccess: true
      InlineJavascriptRequirement: {}
      StepInputExpressionRequirement: {}
      SchemaDefRequirement:
        types:
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/ogc.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/experimental/api-endpoint.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/experimental/discovery.yaml
    inputs:
      target_datetime:
        label: Target datetime
        doc: Target datetime in ISO 8601 format
        type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#DateTime
      bbox:
        label: Area of interest
        doc: AOI polygon (bbox field will be used for STAC bbox)
        type: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml#Polygon
    outputs:
      search_request_norm: 
        type: https://raw.githubusercontent.com/eoap/schemas/main/experimental/discovery.yaml#STACSearchSettings
    expression: |
      ${
        const dt = inputs.target_datetime?.value;
        if (!dt) throw new Error("target_datetime.value is required");

        const poly = inputs.bbox;
        const bb = poly?.bbox;
        if (!bb || !Array.isArray(bb) || bb.length !== 4) {
          throw new Error("bbox.bbox must be [minx,miny,maxx,maxy]");
        }

        // Build the base request (your fixed defaults)
        const sr = {
          collections: ["SENTINEL-1"],
          bbox: bb,
          "filter-lang": "cql2-json",
          filter: {
            op: "and",
            args: [
              {
                op: "in",
                args: [
                  { property: "productType" },
                  ["IW_GRHD_1S", "IW_GRDH_1S"]
                ]
              }
            ]
          }
        };

        // Add datetime interval (±6 days)
        const t = Date.parse(dt);
        if (Number.isNaN(t)) throw new Error("Invalid datetime: " + dt);

        const iso = (ms) => new Date(ms).toISOString().replace(/\.\d+Z$/, "Z");
        const interval = {
          start: { value: iso(t - 6 * 864e5) },
          end:   { value: iso(t + 6 * 864e5) }
        };

        sr["datetime-interval"] = interval;
        sr.datetime_interval = interval; // keep alias for compatibility

        console.error("SEARCH_REQUEST BUILT SUCCESSFULLY");
        console.error(JSON.stringify(sr, null, 2));
        
        return { search_request_norm: sr };
      }

# =====================================

  - id: convert-search
    class: CommandLineTool
    label: Gets the item self hrefs
    doc: Gets the item self hrefs from a STAC search result
    baseCommand: ["convert-search"]
    inputs:
      target_datetime:
        label: Target datetime
        doc: Target datetime in ISO 8601 format
        type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#DateTime
        inputBinding:
          prefix: --target-datetime
          valueFrom: $(self.value)
      search_results:
        label: Search Results
        doc: Search results from the discovery step
        type: File
        inputBinding:
          prefix: --search-results
    outputs:
      items:
        type:
          type: array
          items: string
        outputBinding:
          glob: items.json
          loadContents: true
          outputEval: ${ return JSON.parse(self[0].contents); }

    requirements: 
      NetworkAccess:
        networkAccess: true
      InlineJavascriptRequirement: {}
      StepInputExpressionRequirement: {}
      DockerRequirement:
        dockerPull: docker.io/library/convert-search:latest 
      SchemaDefRequirement:
        types:
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/ogc.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/experimental/api-endpoint.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/experimental/discovery.yaml


# =====================================

  - id: s1_subworkflow
    label: Sub-workflow to process searched S1 data
    class: Workflow
    doc: Stage-in, OST processing, creation of COG
    
    requirements: 
      NetworkAccess:
        networkAccess: true
      InlineJavascriptRequirement: {}
      StepInputExpressionRequirement: {}
      SchemaDefRequirement:
        types:
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/ogc.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/experimental/api-endpoint.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/experimental/discovery.yaml
    inputs:
      reference_ID:
        label: Product reference ID
        type: string
      bbox:
        label: Bounding Box
        doc: Bounding box [minx, miny, maxx, maxy] in the raster CRS
        type:
          - "null"
          - type: array
            items: double
      resolution:
        type: int
        label: Resolution
        doc: Resolution in metres
      ard-type:
        label: ARD type
        doc: Type of analysis-ready data to produce
        type:
        - symbols:
          - OST_GTC
          - OST-RTC
          - CEOS
          - Earth-Engine
          type: enum
      with-speckle-filter:
        label: Speckle filter
        doc: Whether to apply a speckle filter
        type:
        - symbols:
          - APPLY-FILTER
          - NO-FILTER
          type: enum
      resampling-method:
        label: Resampling method
        doc: Resampling method to use
        type:
        - symbols:
          - BILINEAR_INTERPOLATION
          - BICUBIC_INTERPOLATION
          type: enum
    outputs:
      ost_ard_cog:
        label: OST ARD COG output
        doc: OST ARD COG output in a STAC catalog structure
        outputSource: to-stac-catalog/ost_ard_cog
        type: Directory
    steps:
      stage_in:
        label: Stage-in S1 data 
        doc: Stage-in S1 data with Arvesto
        in:
          reference_ID: reference_ID
        run: "#stage-in"
        out: [staged]
      run_script:
        run: "#ost_run"
        in:
          input: stage_in/staged
          resolution: resolution
          ard-type: ard-type
          with-speckle-filter: with-speckle-filter
          resampling-method: resampling-method
        out: [ost_ard]
      to-stac-catalog:
        run: "#to-stac-catalog"
        in:
          input_tif: run_script/ost_ard # dir containinig the OST-processed TIFF to write to COG
          bbox: bbox
          reference_ID: reference_ID # for the reference_ID to fix the STAC Item
        out: [ost_ard_cog]

# ======================================

  - id: stage-in
    class: CommandLineTool
    label: harvest products from CDSE
    baseCommand:
      - /bin/bash
      - arvesto.sh
    inputs:
      reference_ID:
        label: Product reference ID
        doc: Product reference ID
        type: string
    outputs:
      staged:
        label: Staged products paths
        doc: Staged products paths
        type: Directory
        outputBinding:
          glob: $(inputs.reference_ID)
    requirements:
      NetworkAccess:
        networkAccess: true
      DockerRequirement:
        dockerPull: cr.terradue.com/seda/arvesto:0.6.3-develop
      ResourceRequirement:
        coresMax: 1
        ramMax: 2000
      InlineJavascriptRequirement: {}
      InitialWorkDirRequirement:
        listing:
        - entryname: arvesto.sh
          entry: |-
            #!/bin/bash
            set -euo pipefail
            set -ex
            
            # Extract ref and uid
            uid="${return inputs.reference_ID;}"
            echo $uid

            # CDSE creds
            export CDSE_ACCESS_KEY_ID=$CDSE_AWS_ACCESS_KEY_ID
            export CDSE_SECRET_ACCESS_KEY=$CDSE_AWS_SECRET_ACCESS_KEY
            export CDSE_SERVICE_URL=$CDSE_ENDPOINT_URL
            
            # Stagein with arvesto
            arvesto download --product $uid.SAFE --output $uid --dump-stac-catalog 
            
            # Check if the directory was created
            if [[ -d $uid/$uid/$uid.SAFE ]]; then
              echo "Directory $uid.SAFE created."
              # find $uid/$uid/$uid.SAFE -maxdepth 2 -type f
            else
              echo "Directory $uid.SAFE was not created"
            fi
            
            # Check STAC item and print
            stac_json="$uid/$uid/$uid.json"
            if [[ -f "$stac_json" ]]; then
              echo "Found STAC item: $stac_json"
            else
              echo "Missing STAC item: $stac_json"
              exit 1
            fi
            
            rm arvesto.sh
            exit 0

# =====================================

  - id: ost_run
    class: CommandLineTool
    baseCommand: ["/bin/bash", "run_me.sh"]
    arguments:
      - --wipe-cwd
    inputs:
      input:
        type: Directory
        inputBinding:
          position: 1
      resolution:
        type: int
        inputBinding:
          prefix: --resolution
      ard-type:
        type:
        - symbols:
          - OST_GTC
          - OST-RTC
          - CEOS
          - Earth-Engine
          type: enum
        inputBinding:
          prefix: --ard-type
      with-speckle-filter:
        type:
        - symbols: 
          - APPLY-FILTER
          - NO-FILTER
          type: enum
        inputBinding:
          valueFrom: |
            $(self == "APPLY-FILTER" ? "--with-speckle-filter" : null)
      resampling-method:
        type:
        - symbols:
          - BILINEAR_INTERPOLATION
          - BICUBIC_INTERPOLATION
          type: enum
        inputBinding:
          prefix: --resampling-method
      cdse-user:
        type: string?
        inputBinding:
          prefix: --cdse-user
      cdse-password:
        type: string?
        inputBinding:
          prefix: --cdse-password

    outputs:
      ost_ard:
        outputBinding:
          glob: .
        type: Directory

    requirements:
      DockerRequirement:
        dockerPull: cr.terradue.com/eo-services/opensartoolkit:1.0.0
      NetworkAccess:
        networkAccess: true
      ResourceRequirement:
        coresMax: 6
        ramMax: 24000
      EnvVarRequirement:
        envDef:
          INPUT_DIR: $(inputs.input.path)
      InlineJavascriptRequirement: {}
      InitialWorkDirRequirement:
        listing:
        - entryname: run_me.sh
          entry: |-
            #!/bin/bash
            set -e  # Stop on error
            set -x  # Debug mode
            
            echo "OpenSarToolkit START"
            find .
            
            echo "--------------------------------"
            echo "Input directory path: $INPUT_DIR"
            find $INPUT_DIR
            echo "--------------------------------"
            
            # Check that manifest.safe file exists, and print full path 
            if [ \$((\$(find $INPUT_DIR -name "manifest.safe" | wc -l))) -eq 0 ]
            then
              echo "Error: manifest.safe file not found, check staged-in data. Stopping execution"
              exit 1
            fi

            found_path=\$(find "$INPUT_DIR" -name "manifest.safe" | head -n 1)
            echo "$found_path"

            echo python3 /usr/local/lib/python3.8/dist-packages/ost/app/preprocessing.py "$@"
            python3 /usr/local/lib/python3.8/dist-packages/ost/app/preprocessing.py "$@"
            
            res=$?         

            # Print dir content
            echo "Print PWD path and content: $PWD"
            echo $PWD
            ls -latr *            
                    
            echo "END of OpenSarToolkit"
            set +x
            exit $res

# =========================================

  - id: to-stac-catalog
    class: CommandLineTool
    baseCommand: ["stac-catalog"]
    inputs:
      input_tif:
        label: Input TIFF file
        type: Directory
        inputBinding:
          prefix: --input-tif
      reference_ID:
        label: Product reference ID
        type: string
        inputBinding:
          prefix: --reference-id
      bbox:
        label: Bounding Box
        doc: Bounding box [minx, miny, maxx, maxy] in the raster CRS
        type: 
          - "null"
          - type: array
            items: double
        inputBinding:
          prefix: --bbox
          separate: true

    outputs:
      ost_ard_cog:
        type: Directory
        outputBinding:
          glob: $(inputs.reference_ID + "-COG")
        
    requirements:
      DockerRequirement:
        dockerPull: docker.io/library/stac-catalog:latest
      NetworkAccess:
        networkAccess: true
      ResourceRequirement:
        coresMax: 6
        ramMax: 24000
