# SPDX-FileCopyrightText: (C) 2025 pierventre
# SPDX-License-Identifier: MIT

from llama_index.core import VectorStoreIndex, SimpleDirectoryReader, Settings, StorageContext, load_index_from_storage
from llama_index.core.agent.workflow import AgentWorkflow
from llama_index.llms.ollama import Ollama
from llama_index.embeddings.huggingface import HuggingFaceEmbedding
import asyncio
import os

# Settings control global defaults
Settings.embed_model = HuggingFaceEmbedding(model_name="BAAI/bge-base-en-v1.5")
Settings.llm = Ollama(
    model="llama3.1",
    request_timeout=360.0,
    # Manually set the context window to limit memory usage
    context_window=8000,
)

storage_dir = "storage"
index_file = os.path.join(storage_dir, "docstore.json")

if os.path.exists(index_file):
    # Load the index from disk
    print("Loading index from disk.")
    storage_context = StorageContext.from_defaults(persist_dir=storage_dir)
    index = load_index_from_storage(storage_context)
    print("Loaded index from disk.")
else:
    # Build the index and persist it
    print("Building index.")
    os.makedirs(storage_dir, exist_ok=True)  # Ensure directory exists
    documents = SimpleDirectoryReader("data").load_data()
    storage_context = StorageContext.from_defaults()
    index = VectorStoreIndex.from_documents(
        documents,
        embed_model=Settings.embed_model,
        storage_context=storage_context,
    )
    index.storage_context.persist(persist_dir=storage_dir)
    print("Built and persisted new index.")

# Create a RAG tool using LlamaIndex
query_engine = index.as_query_engine(
    # we can optionally override the llm here
    llm=Settings.llm,
)

def multiply(a: float, b: float) -> float:
    """Useful for multiplying two numbers."""
    return a * b

async def search_documents(query: str) -> str:
    """Useful for answering natural language questions about an personal essay written by Paul Graham."""
    response = await query_engine.aquery(query)
    return str(response)

# Create an enhanced workflow with both tools
agent = AgentWorkflow.from_tools_or_functions(
    [multiply, search_documents],
    llm=Settings.llm,
    system_prompt="""You are a helpful assistant that can perform calculations
    and search through documents to answer questions.""",
)

# Now we can ask questions about the documents or do calculations
async def main():
    response = await agent.run(
        "What did the author of the essay do in college? Also, what's 7 * 8?"
    )
    print(response)

    response = await agent.run(
        "What is the author's name?"
    )
    print(response)

# Run the agent
if __name__ == "__main__":
    asyncio.run(main())
