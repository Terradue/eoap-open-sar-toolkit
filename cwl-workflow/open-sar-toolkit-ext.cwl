cwlVersion: v1.2
$namespaces:
  s: https://schema.org/

schemas:
- http://schema.org/version/9.0/schemaorg-current-http.rdf

# Software 
s:name: OpenSarToolkit 
s:description: Preprocessing an S1 image with OpenSarToolkit OST.
s:dateCreated: '2026-03-10'
s:license:
  '@type': s:CreativeWork
  s:identifier: CC-BY-4.0

# Discoverability and citation
s:keywords:
- CWL
- CWL Workflow
- Workflow
- Earth Observation
- Earth Observation application package
- '@type': s:DefinedTerm
  s:description: delineation
  s:name: application-type
- '@type': s:DefinedTerm
  s:description: terrain
  s:name: domain
- '@type': s:DefinedTerm
  s:inDefinedTermSet: https://gcmd.earthdata.nasa.gov/kms/concepts/concept_scheme/sciencekeywords
  s:termCode: 959f1861-a776-41b1-ba6b-d23c71d4d1eb

# Run-time environment
s:operatingSystem:
- Linux
- MacOS X
s:softwareRequirements:
- https://cwltool.readthedocs.io/en/latest/
- https://www.python.org/

# Current version of the software
s:softwareVersion: 2.2.1
s:softwareHelp:
  '@type': s:CreativeWork
  s:name: DeveloperGuide 
  s:url: https://terradue.github.io/eoap-open-sar-toolkit/

# Publisher
s:publisher:
  '@type': s:Organization
  s:name: Terradue Srl
  s:email: info@terradue.com
  s:identifier: https://ror.org/0069cx113

# Authors & Contributors
s:author:
- '@type': s:Person
  s:affiliation:
    '@type': s:Organization
    s:name: Food and Agriculture Organization of the United Nations
    s:identifier: https://ror.org/00pe0tf51
  s:familyName: Vollrath
  s:givenName: Andreas
  s:identifier: https://github.com/BuddyVolly
  s:email: andreas.vollrath@fao.org

- '@type': s:Person
  s:affiliation:
    '@type': s:Organization
    s:name: Brockmann Consult
    s:identifier: https://ror.org/04r0k9g65
  s:familyName: Lurcock
  s:givenName: Pontus
  s:identifier: https://orcid.org/0000-0001-6994-071X
  s:sameAs: https://github.com/pont-us
  s:email: pontus.lurcock@brockmann-consult.de

s:contributor:
- '@type': s:Role
  s:roleName: Researcher
  s:additionalType: http://purl.org/spar/datacite/Researcher
  s:contributor:
    '@type': s:Person
    s:affiliation:
      '@type': s:Organization
      s:name: Terradue Srl
      s:identifier: https://ror.org/0069cx113
    s:email: simone.vaccari@terradue.com
    s:familyName: Vaccari
    s:givenName: Simone
    s:identifier: https://orcid.org/0000-0002-2757-4165
- '@type': s:Role
  s:roleName: Researcher
  s:additionalType: http://purl.org/spar/datacite/Researcher
  s:contributor:
    '@type': s:Person
    s:affiliation:
      '@type': s:Organization
      s:name: Terradue Srl
      s:identifier: https://ror.org/0069cx113
    s:email: frank.loeschau@terradue.com
    s:familyName: Löschau
    s:givenName: Frank
    s:identifier: https://orcid.org/0000-0002-2757-4165


# =============
# CWL Workflow 
# =============
$graph:
  - id: opensartoolkit
    class: Workflow
    label: OpenSarToolkit
    doc: Preprocessing an S1 image with OST
    requirements: 
      NetworkAccess:
        networkAccess: true
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
      days_before:
        label: Selection period end (days before target_datetime)
        doc: Number of days (integer)
        type: int?
      days_after:
        label: Selection period end (days after target_datetime)
        doc: Number of days (integer)
        type: int?
      bbox:
        label: Area of interest
        doc: AOI polygon (bbox field will be used for STAC bbox)
        type: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml#Polygon
      reference:
        label: Reference product ID
        doc: Sentinel-1 identifier or CDSE UID of initial product (optional)
        type: string?
      max_output:
        label: Maximum number of output items
        doc: Maximum number of output items (for debug purposes only)
        type: int?
    outputs:
      output:
        label: OST ARD COG output
        doc: OST ARD COG output in a STAC catalog structure
        type: Directory[]
        outputSource: loop/ost_ard_cog

    steps:
      build_search_request:
        run: "#build_search_request"
        label: Build search_request and add datetime-interval
        in:
          target_datetime: target_datetime
          days_before: days_before
          days_after: days_after
          bbox: bbox
          reference: reference
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
          input_bbox: bbox
          reference: reference
        out: [items]
      loop:
        run: "#loop"
        label: Loop for sub-workflow to process searched S1 data
        doc: Loop for sub-workflow to process searched S1 data
        in:
          reference_ids: convert_search/items
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
      days_before:
        label: Selection period end (days before target_datetime)
        doc: Number of days (integer)
        type: int?
      days_after:
        label: Selection period end (days after target_datetime)
        doc: Number of days (integer)
        type: int?
      bbox:
        label: Area of interest
        doc: AOI polygon (bbox field will be used for STAC bbox)
        type: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml#Polygon
      reference:
        label: Reference product ID
        doc: Sentinel-1 identifier or CDSE UID of initial product (optional)
        type: string?
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

        // Increase search period if reference is set
        const days_before = (inputs.reference ? inputs.days_before : 0) || 0;
        const days_after = (inputs.reference ? inputs.days_after : 0) || 0;
        const interval = {
          start: { value: iso(t - (6 + days_before) * 864e5) },
          end:   { value: iso(t + (6 + days_after) * 864e5) }
        };

        sr["datetime-interval"] = interval;
        sr.datetime_interval = interval; // keep alias for compatibility

        sr["max-items"] = 500

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
      input_bbox:
        label: Area of interest
        doc: AOI polygon (bbox field will be used for STAC bbox)
        type: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml#Polygon
        inputBinding:
          prefix: --input-bbox
          valueFrom: $(self.bbox.join(","))
      reference:
        label: Reference product ID
        doc: Sentinel-1 identifier or CDSE UID of initial product (optional)
        type: string?
        inputBinding:
          prefix: --reference

    outputs:
      items:
        type:
          type: array
          items: string
        outputBinding:
          glob: items.json
          loadContents: true
          outputEval: |
            ${
              if (!self[0].contents || self[0].contents.trim() === "") {
                return [];
              }
              return JSON.parse(self[0].contents);
            }
    requirements: 
      NetworkAccess:
        networkAccess: true
      InlineJavascriptRequirement: {}
      StepInputExpressionRequirement: {}
      DockerRequirement:
        dockerPull: convert-search:local-test
      SchemaDefRequirement:
        types:
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/ogc.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/experimental/api-endpoint.yaml
          - $import: https://raw.githubusercontent.com/eoap/schemas/main/experimental/discovery.yaml

# =====================================

  - id: loop
    class: CommandLineTool
    baseCommand: ["python3", "loop.py"]

    requirements:
      InlineJavascriptRequirement: {}
      InitialWorkDirRequirement:
        listing:
          - entryname: loop.py
            entry: |-
              import sys
              import subprocess

              print(sys.argv, file=sys.stderr)
              print(sys.argv, file=sys.stdout)
              
              bbox = [float(c) for c in sys.argv[1].split(",")]
              resolution = sys.argv[2]
              ard_type = sys.argv[3]
              with_speckle_filter = sys.argv[4]
              resampling_method = sys.argv[5]
              reference_ids = sys.argv[6:]

              print(f"Starting sequential execution for {len(reference_ids)} items", file=sys.stderr)
              
              for reference_id in reference_ids:
                with open("job.yml", "w") as f:
                  print(f"resolution: {resolution}", file=f)
                  print(f"ard-type: {ard_type}", file=f)
                  print(f"with-speckle-filter: {with_speckle_filter}", file=f)
                  print(f"resampling-method: {resampling_method}", file=f)
                  print(f"bbox: {bbox}", file=f)
                  print(f"reference_id: {reference_id}", file=f)

                print(f"Executing subworkflow for item: '{reference_id}'", file=sys.stderr)
                
                # Call cwltool, passing the exact same file name, pointing to the subworkflow #id
                # We use the current directory context to target the main running file.
                command = [
                  "cwltool", 
                  "--preserve-environment", "CDSE_ENDPOINT_URL",
                  "--preserve-environment", "CDSE_AWS_ACCESS_KEY_ID",
                  "--preserve-environment", "CDSE_AWS_SECRET_ACCESS_KEY",
                  "open-sar-toolkit-ext.cwl#s1_subworkflow",
                  "job.yml",
                ]

                print(command, file=sys.stderr)
                
                result = subprocess.run(command, capture_output=True, text=True)
                if result.returncode != 0:
                  print(f"Error executing subworkflow for item {reference_id}:", file=sys.stderr)
                  print(result.stderr, file=sys.stderr)
                  sys.exit(1)
                    
                print(f"Finished execution for item: '{reference_id}'", file=sys.stderr)

    inputs:
      reference_ids:
        label: Product reference IDs
        type:
          type: array
          items: string
        inputBinding:
          position: 10
      bbox:
        label: Bounding Box
        doc: Bounding box [minx, miny, maxx, maxy] in the raster CRS
        type:
          - "null"
          - type: array
            items: double
        inputBinding:
          position: 1
          valueFrom: $(self.join(","))
      resolution:
        type: int
        label: Resolution
        doc: Resolution in metres
        inputBinding:
          position: 2
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
        inputBinding:
          position: 3
      with-speckle-filter:
        label: Speckle filter
        doc: Whether to apply a speckle filter
        type:
        - symbols:
          - APPLY-FILTER
          - NO-FILTER
          type: enum
        inputBinding:
          position: 4
      resampling-method:
        label: Resampling method
        doc: Resampling method to use
        type:
        - symbols:
          - BILINEAR_INTERPOLATION
          - BICUBIC_INTERPOLATION
          type: enum
        inputBinding:
          position: 5

    outputs:
      ost_ard_cog:
        type: Directory[]
        outputBinding:
          glob: "S1*-COG"
    stdout: sequential_output.txt


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
      reference_id:
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
          reference_id: reference_id
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
          reference_id: reference_id # for the reference_id to fix the STAC Item
        out: [ost_ard_cog]

# ======================================

  - id: stage-in
    class: CommandLineTool
    label: harvest products from CDSE
    baseCommand:
      - /bin/bash
      - arvesto.sh
    inputs:
      reference_id:
        label: Product reference ID
        doc: Product reference ID
        type: string
    outputs:
      staged:
        label: Staged products paths
        doc: Staged products paths
        type: Directory
        outputBinding:
          glob: $(inputs.reference_id)
    requirements:
      NetworkAccess:
        networkAccess: true
      DockerRequirement:
        #dockerPull: cr.terradue.com/seda/arvesto:0.6.3-develop
        dockerPull: arvesto:local-test
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
            uid="${return inputs.reference_id;}"
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
        dockerPull: ghcr.io/terradue/eoap-open-sar-toolkit/opensartoolkit:1.0.0
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
      reference_id:
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
          glob: $(inputs.reference_id + "-COG")
        
    requirements:
      DockerRequirement:
        dockerPull: ghcr.io/terradue/eoap-open-sar-toolkit/stac-catalog:latest-dev
      NetworkAccess:
        networkAccess: true
      ResourceRequirement:
        coresMax: 6
        ramMax: 24000
