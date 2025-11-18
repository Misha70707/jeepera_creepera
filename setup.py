from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="nexus-autonomous-agent",
    version="0.1.0",
    author="Nexus Development Team",
    description="The Autonomous Coder & Entrepreneur - An AI agent that learns, codes, and sells",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/nexus",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "Topic :: Software Development :: AI/ML",
        "License :: OSI Approved :: Apache Software License",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
    ],
    python_requires=">=3.10",
    install_requires=[
        line.strip()
        for line in open("requirements.txt").readlines()
        if line.strip() and not line.startswith("#")
    ],
    entry_points={
        "console_scripts": [
            "nexus=main:main",
        ],
    },
)
