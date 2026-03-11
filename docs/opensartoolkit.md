# OpenSarToolkit v2.1.8

Preprocessing an S1 image with OpenSarToolkit OST.

> This software is licensed under the terms of the [Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/legalcode) license - SPDX short identifier: [CC-BY-4.0](https://spdx.org/licenses/CC-BY-4.0)
>
> 2026-03-10 - 2026-03-11T12:54:09.024 Copyright [Terradue Srl](mailto:info@terradue.com) - > [https://ror.org/0069cx113](https://ror.org/0069cx113)

## Project Team

### Authors

| Name | Email | Organization | Role | Identifier |
|------|-------|--------------|------|------------|
| Vollrath, Andreas | [andreas.vollrath@fao.org](mailto:andreas.vollrath@fao.org) | [Food and Agriculture Organization of the United Nations](https://ror.org/00pe0tf51) | []() | [https://github.com/BuddyVolly](https://github.com/BuddyVolly) |
| Lurcock, Pontus | [pontus.lurcock@brockmann-consult.de](mailto:pontus.lurcock@brockmann-consult.de) | [Brockmann Consult](https://ror.org/04r0k9g65) | []() | [https://orcid.org/0000-0001-6994-071X](https://orcid.org/0000-0001-6994-071X) |


### Contributors

| Name | Email | Organization | Role | Identifier |
|------|-------|--------------|------|------------|
| Vaccari, Simone | [simone.vaccari@terradue.com](mailto:simone.vaccari@terradue.com) | [Terradue Srl](https://ror.org/0069cx113) | [Researcher](http://purl.org/spar/datacite/Researcher) | [https://orcid.org/0000-0002-2757-4165](https://orcid.org/0000-0002-2757-4165) |



## DeveloperGuide

DeveloperGuide can be found on [https://terradue.github.io/eoap-open-sar-toolkit/](https://terradue.github.io/eoap-open-sar-toolkit/).


## Runtime environment

### Supported Operating Systems

- Linux
- MacOS X

### Requirements

- [https://cwltool.readthedocs.io/en/latest/](https://cwltool.readthedocs.io/en/latest/)
- [https://www.python.org/](https://www.python.org/)


## Software Source code

- Browsable version of the [source repository](https://github.com/Terradue/eoap-open-sar-toolkit.git);
- [Continuous integration](https://github.com/Terradue/eoap-open-sar-toolkit/actions) system used by the project;
- Issues, bugs, and feature requests should be submitted to the following [issue management](https://github.com/Terradue/eoap-open-sar-toolkit/issues) system for this project


---


## opensartoolkit

### CWL Class

[Workflow](https://www.commonwl.org/v1.2/Workflow.html#Workflow)

### Requirements

* [NetworkAccess](https://www.commonwl.org/v1.2/Workflow.html#NetworkAccess)
* [ScatterFeatureRequirement](https://www.commonwl.org/v1.2/Workflow.html#ScatterFeatureRequirement)
* [SubworkflowFeatureRequirement](https://www.commonwl.org/v1.2/Workflow.html#SubworkflowFeatureRequirement)
* [StepInputExpressionRequirement](https://www.commonwl.org/v1.2/Workflow.html#StepInputExpressionRequirement)
* [InlineJavascriptRequirement](https://www.commonwl.org/v1.2/Workflow.html#InlineJavascriptRequirement)
* [SchemaDefRequirement](https://www.commonwl.org/v1.2/Workflow.html#SchemaDefRequirement)

### Inputs

| Id | Type | Label | Doc |
|----|------|-------|-----|
| `resolution` | `int` | Resolution | Resolution in metres |
| `ard-type` | `[ enum ]` | ARD type | Type of analysis-ready data to produce |
| `with-speckle-filter` | `[ enum ]` | Speckle filter | Whether to apply a speckle filter |
| `resampling-method` | `[ enum ]` | Resampling method | Resampling method to use |
| `target_datetime` | `https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#DateTime` | Target datetime | Target datetime in ISO 8601 format |
| `bbox` | `https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml#Polygon` | Area of interest | AOI polygon (bbox field will be used for STAC bbox) |


### Steps

| Id | Runs | Label | Doc |
|----|------|-------|-----|
| [build_search_request](#build_search_request) | `#build_search_request` | Build search_request and add datetime-interval | None |
| [discovery](#odata-client) | `#odata-client` | OData API discovery | Discover STAC items from a OData API endpoint based on a search request |
| [convert_search](#convert-search) | `#convert-search` | Convert Search | Convert Search results to get the item self hrefs |
| [s1_subworkflow](#s1_subworkflow) | `#s1_subworkflow` | Sub-workflow to process searched S1 data | Sub-workflow to process searched S1 data |


### Outputs

| Id | Type | Label | Doc |
|----|------|-------|-----|
| `output` | `Directory[]` | None | None |


### UML Diagrams


#### UML `activity` diagram

![opensartoolkit flow diagram](./opensartoolkit/activity.svg "opensartoolkit activity diagram")

#### UML `component` diagram

![opensartoolkit flow diagram](./opensartoolkit/component.svg "opensartoolkit component diagram")

#### UML `class` diagram

![opensartoolkit flow diagram](./opensartoolkit/class.svg "opensartoolkit class diagram")

#### UML `sequence` diagram

![opensartoolkit flow diagram](./opensartoolkit/sequence.svg "opensartoolkit sequence diagram")

#### UML `state` diagram

![opensartoolkit flow diagram](./opensartoolkit/state.svg "opensartoolkit state diagram")






## build_search_request

### CWL Class

[ExpressionTool](https://www.commonwl.org/v1.2/Workflow.html#ExpressionTool)

### Inputs

| Id | Option | Type |
|----|------|-------|
| `target_datetime` | `--target_datetime` | `https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#DateTime` |
| `bbox` | `--bbox` | `https://raw.githubusercontent.com/eoap/schemas/main/geojson.yaml#Polygon` |




### Run in step

`build_search_request`




## odata-client

### CWL Class

[CommandLineTool](https://www.commonwl.org/v1.2/CommandLineTool.html#CommandLineTool)

### Inputs

| Id | Option | Type |
|----|------|-------|
| `api_endpoint` | `--api_endpoint` | `https://raw.githubusercontent.com/eoap/schemas/main/experimental/api-endpoint.yaml#APIEndpoint` |
| `search_request` | `--search_request` | `https://raw.githubusercontent.com/eoap/schemas/main/experimental/discovery.yaml#STACSearchSettings` |

### Execution usage example:

```
odata-client search $(inputs.api_endpoint.url.value) ${ const args = []; const collections = inputs.search_request.collections; args.push('--collections', collections.join(",")); return args; } ${ const args = []; const bbox = inputs.search_request?.bbox; if (Array.isArray(bbox) && bbox.length >= 4) { args.push('--bbox', ...bbox.map(String)); } return args; } ${ const args = []; const limit = inputs.search_request?.limit; args.push("--limit", (limit ?? 10).toString()); return args; } ${ const maxItems = inputs.search_request?.['max-items']; return ['--max-items', (maxItems ?? 20).toString()]; } ${ const args = []; const filter = inputs.search_request?.filter; const filterLang = inputs.search_request?.['filter-lang']; if (filterLang) { args.push('--filter-lang', filterLang); } if (filter) { args.push('--filter', JSON.stringify(filter)); } return args; } ${ const datetime = inputs.search_request?.datetime; const datetimeInterval = inputs.search_request?.datetime_interval; if (datetime) { return ['--datetime', datetime]; } else if (datetimeInterval) { const start = datetimeInterval.start?.value || '..'; const end = datetimeInterval.end?.value || '..'; return ['--datetime', `${start}/${end}`]; } return []; } ${ const ids = inputs.search_request?.ids; const args = []; if (Array.isArray(ids) && ids.length > 0) { args.push('--ids', ...ids.map(String)); } return args; } ${ const intersects = inputs.search_request?.intersects; if (intersects) { return ['--intersects', JSON.stringify(intersects)]; } return []; } --save discovery-output.json \
--api_endpoint <API_ENDPOINT> \
--search_request <SEARCH_REQUEST>
```


### Run in step

`discovery`




## convert-search

### CWL Class

[CommandLineTool](https://www.commonwl.org/v1.2/CommandLineTool.html#CommandLineTool)

### Inputs

| Id | Option | Type |
|----|------|-------|
| `target_datetime` | `--target-datetime` | `https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#DateTime` |
| `search_results` | `--search-results` | `File` |

### Execution usage example:

```
convert-search \
--target-datetime <TARGET_DATETIME> \
--search-results <SEARCH_RESULTS>
```


### Run in step

`convert_search`




## s1_subworkflow

### CWL Class

[Workflow](https://www.commonwl.org/v1.2/Workflow.html#Workflow)

### Requirements

* [NetworkAccess](https://www.commonwl.org/v1.2/Workflow.html#NetworkAccess)
* [InlineJavascriptRequirement](https://www.commonwl.org/v1.2/Workflow.html#InlineJavascriptRequirement)
* [StepInputExpressionRequirement](https://www.commonwl.org/v1.2/Workflow.html#StepInputExpressionRequirement)
* [SchemaDefRequirement](https://www.commonwl.org/v1.2/Workflow.html#SchemaDefRequirement)

### Inputs

| Id | Type | Label | Doc |
|----|------|-------|-----|
| `reference_ID` | `string` | Product reference ID | None |
| `bbox` | `[ null, double[] ]` | Bounding Box | Bounding box [minx, miny, maxx, maxy] in the raster CRS |
| `resolution` | `int` | Resolution | Resolution in metres |
| `ard-type` | `[ enum ]` | ARD type | Type of analysis-ready data to produce |
| `with-speckle-filter` | `[ enum ]` | Speckle filter | Whether to apply a speckle filter |
| `resampling-method` | `[ enum ]` | Resampling method | Resampling method to use |


### Steps

| Id | Runs | Label | Doc |
|----|------|-------|-----|
| [stage_in](#stage-in) | `#stage-in` | Stage-in S1 data | Stage-in S1 data with Arvesto |
| [run_script](#ost_run) | `#ost_run` | None | None |
| [to-stac-catalog](#to-stac-catalog) | `#to-stac-catalog` | None | None |


### Outputs

| Id | Type | Label | Doc |
|----|------|-------|-----|
| `ost_ard_cog` | `Directory` | OST ARD COG output | OST ARD COG output in a STAC catalog structure |


### UML Diagrams


#### UML `activity` diagram

![s1_subworkflow flow diagram](./s1_subworkflow/activity.svg "s1_subworkflow activity diagram")

#### UML `component` diagram

![s1_subworkflow flow diagram](./s1_subworkflow/component.svg "s1_subworkflow component diagram")

#### UML `class` diagram

![s1_subworkflow flow diagram](./s1_subworkflow/class.svg "s1_subworkflow class diagram")

#### UML `sequence` diagram

![s1_subworkflow flow diagram](./s1_subworkflow/sequence.svg "s1_subworkflow sequence diagram")

#### UML `state` diagram

![s1_subworkflow flow diagram](./s1_subworkflow/state.svg "s1_subworkflow state diagram")






## stage-in

### CWL Class

[CommandLineTool](https://www.commonwl.org/v1.2/CommandLineTool.html#CommandLineTool)

### Inputs

| Id | Option | Type |
|----|------|-------|
| `reference_ID` | `--reference_ID` | `string` |

### Execution usage example:

```
/bin/bash arvesto.sh \
--reference_ID <REFERENCE_ID>
```


### Run in step

`stage_in`




## ost_run

### CWL Class

[CommandLineTool](https://www.commonwl.org/v1.2/CommandLineTool.html#CommandLineTool)

### Inputs

| Id | Option | Type |
|----|------|-------|
| `input` | `--input` | `Directory` |
| `resolution` | `--resolution` | `int` |
| `ard-type` | `--ard-type` | `[ enum ]` |
| `with-speckle-filter` | `--with-speckle-filter` | `[ enum ]` |
| `resampling-method` | `--resampling-method` | `[ enum ]` |
| `cdse-user` | `--cdse-user` | `[ null, string ]` |
| `cdse-password` | `--cdse-password` | `[ null, string ]` |

### Execution usage example:

```
/bin/bash run_me.sh --wipe-cwd \
--input <INPUT> \
--resolution <RESOLUTION> \
--ard-type <ARD-TYPE> \
--with-speckle-filter <WITH-SPECKLE-FILTER> \
--resampling-method <RESAMPLING-METHOD> \
(--cdse-user <CDSE-USER>) \
(--cdse-password <CDSE-PASSWORD>)
```


### Run in step

`run_script`




## to-stac-catalog

### CWL Class

[CommandLineTool](https://www.commonwl.org/v1.2/CommandLineTool.html#CommandLineTool)

### Inputs

| Id | Option | Type |
|----|------|-------|
| `input_tif` | `--input-tif` | `Directory` |
| `reference_ID` | `--reference-id` | `string` |
| `bbox` | `--bbox` | `[ null, double[] ]` |

### Execution usage example:

```
stac-catalog \
--input-tif <INPUT_TIF> \
--reference-id <REFERENCE_ID> \
(--bbox <BBOX>)
```


### Run in step

`to-stac-catalog`



### Run in step

`s1_subworkflow`
