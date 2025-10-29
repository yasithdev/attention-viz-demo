import os
import argparse
from openfold.data import data_pipeline
from openfold.data.tools import hhsearch, hmmsearch
from openfold.utils.script_utils import parse_fasta
from scripts.utils import add_data_args  # Reuse your existing data-related CLI args

def run_alignment(fasta_path, output_dir, args):
    with open(fasta_path, "r") as fp:
        tags, seqs = parse_fasta(fp.read())
    tag = '-'.join(tags)

    alignment_dir = os.path.join(output_dir, tag)
    os.makedirs(alignment_dir, exist_ok=True)

    if "multimer" in args.config_preset:
        template_searcher = hmmsearch.Hmmsearch(
            binary_path=args.hmmsearch_binary_path,
            hmmbuild_binary_path=args.hmmbuild_binary_path,
            database_path=args.pdb_seqres_database_path,
        )
    else:
        template_searcher = hhsearch.HHSearch(
            binary_path=args.hhsearch_binary_path,
            databases=[args.pdb70_database_path],
        )

    alignment_runner = data_pipeline.AlignmentRunner(
        jackhmmer_binary_path=args.jackhmmer_binary_path,
        hhblits_binary_path=args.hhblits_binary_path,
        uniref90_database_path=args.uniref90_database_path,
        mgnify_database_path=args.mgnify_database_path,
        bfd_database_path=args.bfd_database_path,
        uniref30_database_path=args.uniref30_database_path,
        uniclust30_database_path=args.uniclust30_database_path,
        uniprot_database_path=args.uniprot_database_path,
        template_searcher=template_searcher,
        use_small_bfd=args.bfd_database_path is None,
        no_cpus=args.cpus
    )

    try:
        alignment_runner.run(fasta_path, alignment_dir)
        print(f"Alignments for {fasta_path} saved to {alignment_dir}")
    except Exception as e:
        print(f"Failed on {fasta_path}: {e}")

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("fasta_path", type=str)
    parser.add_argument("output_dir", type=str)
    parser.add_argument("--config_preset", type=str, default="model_1")
    parser.add_argument("--cpus", type=int, default=4)

    # This adds all required data-related CLI arguments from your full pipeline
    add_data_args(parser)

    args = parser.parse_args()
    return args

if __name__ == "__main__":
    args = parse_args()
    run_alignment(args.fasta_path, args.output_dir, args)

