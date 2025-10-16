# Daylily Ephemeral Cluster profile

This guide explains how to run **nf-core/sarek** on an AWS ParallelCluster provisioned
with [`daylily-ephemeral-cluster`](https://github.com/Daylily-Informatics/daylily-ephemeral-cluster).
The cluster ships with a shared FSx for Lustre mount at `/fsx` that exposes the
reference bundle produced by [`daylily-omics-references`](https://github.com/Daylily-Informatics/daylily-omics-references).

The pipeline ships dedicated configuration profiles named `daylily_ephemeral_cluster`
(aliased to `daylily`) and `daylily_ephemeral_cluster_local` (aliased to
`daylily_local`) that

- configure the Slurm or local executor used by the cluster,
- points Sarek to the reference files under `/fsx/data/`, and
- enables Singularity with the cache stored on the shared FSx volume.

> [!NOTE]
> The profile automatically populates reference paths for the
> `DAYLILY.GRCh38` genome. Support for additional genomes can be added by
> extending the configuration locally if required.

## Prerequisites

1. Deploy the cluster following the instructions in the
   [`daylily-ephemeral-cluster`](https://github.com/Daylily-Informatics/daylily-ephemeral-cluster)
   repository.
2. Log in to the head node and ensure that Nextflow, Singularity, and the
   `dyoainit` helper script provided by Daylily are available on your `$PATH`.
3. Create a working directory on FSx (for example `/fsx/analysis_results/ubuntu/sarek-demo`).
4. Clone the Sarek repository into that directory or download a release tarball.
5. (Optional) Source `dyoainit` to populate Daylily-specific environment variables:

   ```bash
   source dyoainit --project <project-name>
   ```

   The profile uses `DAY_PROJECT`, `DAYLILY_SLURM_QUEUE`, and `DAY_SCRATCH`
   when they are defined to fine-tune Slurm submissions.

## Running the pipeline

From the working directory run Sarek with the Daylily profile:

```bash
nextflow run nf-core/sarek \
    -r <VERSION> \
    -profile daylily \
    --genome DAYLILY.GRCh38 \
    --input /path/to/samplesheet.csv \
    --outdir /fsx/analysis_results/$USER/sarek/<run-name>
```

Key points to keep in mind:

- `--genome DAYLILY.GRCh38` selects the Daylily reference paths declared in the
  profile. You can override individual parameters (e.g. `--fasta`) if you need
  to test alternative resources.
- Jobs are submitted to Slurm. Use `DAYLILY_SLURM_QUEUE` or specify
  `ext.queue` per process when you need to target a different partition.
- Containers are pulled once into `/fsx/resources/environments/containers/$USER`
  and reused by subsequent runs.
- The working directory defaults to `/fsx/work/$USER/sarek/work`. Export `NXF_WORK`
  if you prefer a different location.

If you prefer to execute the workflow on the head node without submitting to
Slurm, switch to the local variant:

```bash
nextflow run nf-core/sarek \
    -r <VERSION> \
    -profile daylily_local \
    --genome DAYLILY.GRCh38 \
    --input /path/to/samplesheet.csv \
    --outdir /fsx/analysis_results/$USER/sarek/<run-name>
```

This uses Nextflow's local executor while keeping all Daylily-specific paths and
defaults.

For more information about the profile defaults see
[`conf/daylily_ephemeral_cluster.config`](../../conf/daylily_ephemeral_cluster.config)
and [`conf/daylily_ephemeral_cluster_local.config`](../../conf/daylily_ephemeral_cluster_local.config).
