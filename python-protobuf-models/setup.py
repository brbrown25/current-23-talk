import setuptools
from os import environ

version = environ.get("PYTHON_BBROWNSOUND_SCHEMA_VERSION")
if version is None:
    raise ValueError('missing PYTHON_BBROWNSOUND_SCHEMA_VERSION environment variable!')

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setuptools.setup(
    name="python-protobuf-models",
    version=version,
    author="Brandon Brown",
    author_email="brandon@bbrownsound.com",
    description="Bbrownsound Protobuf Models",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/brbrown25/current-23-talk",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    package_dir={"": "src"},
    packages=setuptools.find_packages(where="src"),
    python_requires=">=3.6",
)
