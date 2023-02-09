import nbformat as nbf
import argparse


OUTPUT = "new1.ipynb"


def build_notebook(subscription):

    nb = nbf.v4.new_notebook()

    msg_welcome = """\
# AZHOP AzureML SDK (python) Entry point
Use this self-created template to run your parallel job in AzureML."""

    code1 = """\
a=2
b=5"""

    nb['cells'] = [nbf.v4.new_markdown_cell(msg_welcome),
                   nbf.v4.new_code_cell(code1)]

    nbf.write(nb, OUTPUT)


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument("-s", "--subscription",
                        help="Subscription", required=True)

    args = parser.parse_args()
    subscription = args.subscription

    build_notebook(subscription)


if __name__ == '__main__':
    main()
