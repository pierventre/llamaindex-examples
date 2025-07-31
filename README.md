# LLama Index Examples

## Overview

This repository contains a couple of examples done using [Llama Index library](https://github.com/run-llama/llama_index). The project contains
Makefile and targets to run locally the examples on your machine by using [Ollama](https://ollama.com).

## Get Started

Instructions on how to install and run the examples

### Dependencies

Firstly, please verify that all dependencies have been installed.

```bash
# Return errors if any dependency is missing
make venv_llamai
```

This make target will create a venv and install all the deps to run the examples.

### Start, Stop, Logs, Status of Ollama

You can start a Ollama process using the following targets

```bash
# Run local-ai process
make ollama-start
```

```bash
# Stop local-ai process
make ollama-stop
```

```bash
# Get logs of local-ai process
make ollama-logs
```

```bash
# Return status of local-ai process
make ollama-status
```

### Run the examples

Use the following target to run all the examples

```bash
# Run the examples
make run-examples
```
