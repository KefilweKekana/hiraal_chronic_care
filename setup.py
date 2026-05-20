from setuptools import setup, find_packages

with open("requirements.txt") as f:
    install_requires = f.read().strip().split("\n")

setup(
    name="hiraal_emr",
    version="1.0.0",
    description="Hiraal Chronic Care EMR - Chronic Disease Management Platform for Somaliland",
    author="Hiraal Health Center",
    author_email="info@hiraalhealth.so",
    packages=find_packages(),
    zip_safe=False,
    include_package_data=True,
    install_requires=install_requires,
)
