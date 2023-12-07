from modules.singleton import SingletonType
from . import chroma_protocol_pb2 as sub_protocol_pb2
from modules.protocol_handle import ProtocolHandle
import chromadb
from chromadb.utils import embedding_functions
from chromadb.utils.batch_utils import create_batches
import json
import copy
import os
from pathlib import Path
import sys
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.document_loaders import UnstructuredFileLoader
import uuid

import six
@six.add_metaclass(SingletonType)
class MyChroma(object):
    protocol_handle = None
    main = None
    ## Note that all plugins share two databases
    client = None
    persistent_client = None
    client_collection = None
    persistent_client_collection = None

    def __init__(self, file_path="./persistent_data"):
        self.protocol_handle = ProtocolHandle()
        from main import Main
        self.main = Main()
        self.client = chromadb.Client()
        ## The database will be automatically created based on the incoming path, which should be in plugin_file
        self.persistent_client = chromadb.PersistentClient(path=file_path)

        model_name = "paraphrase-multilingual-MiniLM-L12-v2"
        if not os.path.exists(model_name):
            if getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'):
                bundle_dir = Path(sys._MEIPASS)
                model_name = Path.cwd() / bundle_dir / "sentence-transformers_paraphrase-multilingual-MiniLM-L12-v2"

        sentence_transformer_ef = embedding_functions.SentenceTransformerEmbeddingFunction(model_name=model_name)

        self.client_collection = self.client.get_or_create_collection("vme",embedding_function=sentence_transformer_ef)
        self.persistent_client_collection = self.persistent_client.get_or_create_collection("vme",embedding_function=sentence_transformer_ef)

        self.register_all_protocol()

    def register_all_protocol(self):
        ## Register all server-side call protocols
        self.protocol_handle.register_protocol_format_with_object(sub_protocol_pb2, self)

    async def load_files(self, data):
        file_paths = data.get("file_paths",[])
        data_type = data.get("type","dynamic")
        is_persistent = data.get("persistent",False)
        space = data.get("space","main")

        for file_path in file_paths:
            if os.path.exists(file_path):
                loader = UnstructuredFileLoader(
                    file_path
                )
                docs = loader.load()
                text_splitter = RecursiveCharacterTextSplitter(separators=["\n\n", "\n", " "],chunk_size=200, chunk_overlap=20)
                load_documents = text_splitter.split_documents(docs)
                documents = [doc.page_content for doc in load_documents]
                metadatas = [doc.metadata for doc in load_documents]
                ids = [str(uuid.uuid1()) for _ in load_documents]
                uris = [file_path for _ in load_documents]
                await self.add_documents(data={"documents":documents,"metadatas":[json.dumps(metadata) for metadata in metadatas],
                                    "ids":ids,"data_type":data_type,"persistent":is_persistent,"space":space,"uris":uris})
        return {"result":True}


    async def S_C_LOAD_FILES(self, client, syncId, data):
        return await self.main.send_service_request(client, syncId, data, self.S_C_LOAD_FILES)

    async def C_S_LOAD_FILES(self, client, syncId ,content):
        result_data = await self.load_files(content)
        await self.S_C_LOAD_FILES(client, syncId, result_data)

    async def unload_files(self, data):
        file_paths = data.get("file_paths",[])
        data_type = data.get("type","dynamic")
        is_persistent = data.get("persistent",False)
        space = data.get("space","main")
        await self.delete_documents(data={"uris":file_paths,
                            "data_type":data_type,"persistent":is_persistent,"space":space})
        return {"result":True}

    async def S_C_UNLOAD_FILES(self, client, syncId, data):
        return await self.main.send_service_request(client, syncId, data, self.S_C_UNLOAD_FILES)


    async def C_S_UNLOAD_FILES(self, client, syncId ,content):
        result_data = await self.unload_files(content)
        await self.S_C_UNLOAD_FILES(client, syncId, result_data)


    async def add_documents(self, data):
        documents = data.get("documents",[])
        metadatas = data.get("metadatas",[])
        ids = data.get("ids",[])
        data_type = data.get("type","dynamic")
        is_persistent = data.get("persistent",False)
        space = data.get("space","main")
        uris = data.get("uris",None)
        
        cur_documents = []
        cur_persistent_documents = []
        
        cur_metadatas = []
        cur_persistent_metadatas = []
        
        cur_ids = []
        cur_persistent_ids = []


        for i in range(len(metadatas)):
            cur_metadata = json.loads(metadatas[i])

            if cur_metadata.get("space","") == "":
                cur_metadata["space"] = space

            if cur_metadata.get("type","") == "":
                cur_metadata["type"] = data_type
            
            cur_id = 0
            if cur_metadata.get("id","") == "":
                cur_id = ids[i]

            if cur_metadata.get("uri","") == "":
                if uris != None and len(uris) > i:
                    cur_metadata["uri"] = uris[i]
                else:
                    cur_metadata["uri"] = ""

            if is_persistent:
                cur_persistent_metadatas.append(cur_metadata)
                cur_persistent_ids.append(cur_id)
                cur_persistent_documents.append(documents[i])
            else:
                cur_metadatas.append(cur_metadata)
                cur_ids.append(cur_id)
                cur_documents.append(documents[i])

        if cur_persistent_ids:
            for batch in create_batches(
                api=self.persistent_client,
                ids=cur_persistent_ids,
                metadatas=cur_persistent_metadatas,
                documents=cur_persistent_documents,
            ):
                uris = batch[2] if batch[2] else None
                if uris:
                    uris = [metadata["uri"] for metadata in uris]
                self.persistent_client_collection.upsert(
                    documents=batch[3] if batch[3] else [],
                    metadatas=batch[2] if batch[2] else None,
                    ids=batch[0],
                    uris = uris,
                )
        if cur_ids:
            for batch in create_batches(
                api=self.client,
                ids=cur_ids,
                metadatas=cur_metadatas,
                documents=cur_documents,
            ):
                uris = batch[2] if batch[2] else None
                if uris:
                    uris = [metadata["uri"] for metadata in uris]
                self.client_collection.upsert(
                    documents=batch[3] if batch[3] else [],
                    metadatas=batch[2] if batch[2] else None,
                    ids=batch[0],
                    uris = uris,
                )
        return {"result":True}

    async def S_C_ADD_DOCUMENTS(self, client, syncId, data):
        return await self.main.send_service_request(client, syncId, data, self.S_C_ADD_DOCUMENTS)


    async def C_S_ADD_DOCUMENTS(self, client, syncId ,content):
        result_data = await self.add_documents(content)
        await self.S_C_ADD_DOCUMENTS(client, syncId, result_data)


    async def delete_documents(self, data):
        ids = data.get("ids",None)
        where = data.get("where",None)
        where_document = data.get("where_document",None)


        data_type = data.get("type",None)
        is_persistent = data.get("persistent",None)
        space = data.get("space",None)
        uris = data.get("uris",None)

        if where!=None:
            where = json.loads(where)

        if where_document!=None:
            where_document = json.loads(where_document)

        if data_type == None:
            pass
        elif data_type == "dynamic":
            if where:
                where = deep_merge(where,{"type":{"$eq":"dynamic"}})
            else:
                where = {"type":{"$eq":"dynamic"}}
        elif data_type == "static":
            if where:
                where = deep_merge(where,{"type":{"$eq":"static"}})
            else:
                where = {"type":{"$eq":"static"}}

        if space == None:
            pass
        else:
            if where:
                where = deep_merge(where,{"space":{"$eq":space}})
            else:
                where = {"space":{"$eq":space}}

        if uris == None:
            pass
        else:
            if where:
                where = deep_merge(where,{"uri":{"$in":uris}})
            else:
                where = {"uri":{"$in":uris}}

        if where and len(where)>1:
            if "$and" not in where:
                cur_where = {"$and":[]}
            else:
                cur_where = {"$and":where["$and"]}
            for key in where:
                if key!="$and":
                    cur_where["$and"].append({key:where[key]})
            where = cur_where

        if where_document and len(where_document)>1:
            if "$and" not in where_document:
                cur_where_document = {"$and":[]}
            else:
                cur_where_document = {"$and":where_document["$and"]}
            for key in where_document:
                if key!="$and":
                    cur_where_document["$and"].append({key:where_document[key]})
            where_document = cur_where_document

        if is_persistent == None:
            self.client_collection.delete(ids=ids,where=where,where_document=where_document)
            self.persistent_client_collection.delete(ids=ids,where=where,where_document=where_document)
        elif is_persistent == True:
            self.persistent_client_collection.delete(ids=ids,where=where,where_document=where_document)
        elif is_persistent == False:
            self.client_collection.delete(ids=ids,where=where,where_document=where_document)

        return {"result":True}

    async def S_C_DELETE_DOCUMENTS(self, client, syncId, data):
        return await self.main.send_service_request(client, syncId, data, self.S_C_DELETE_DOCUMENTS)

    async def C_S_DELETE_DOCUMENTS(self, client, syncId ,content):
        result_data = await self.delete_documents(content)
        await self.S_C_DELETE_DOCUMENTS(client, syncId, result_data)

    async def get_documents(self, data):
        ids = data.get("ids",None)
        where = data.get("where",None)
        where_document = data.get("where_document",None)
        include = data.get("include",["embeddings","metadatas", "documents"])
        
        data_type = data.get("type",None)
        is_persistent = data.get("persistent",None)
        space = data.get("space",None)
        uris = data.get("uris",None)

        if where!=None:
            where = json.loads(where)

        if where_document!=None:
            where_document = json.loads(where_document)

        if data_type == None:
            pass
        elif data_type == "dynamic":
            if where:
                where = deep_merge(where,{"type":{"$eq":"dynamic"}})
            else:
                where = {"type":{"$eq":"dynamic"}}
        elif data_type == "static":
            if where:
                where = deep_merge(where,{"type":{"$eq":"static"}})
            else:
                where = {"type":{"$eq":"static"}}

        if space == None:
            pass
        else:
            if where:
                where = deep_merge(where,{"space":{"$eq":space}})
            else:
                where = {"space":{"$eq":space}}

        if uris == None:
            pass
        else:
            if where:
                where = deep_merge(where,{"uri":{"$in":uris}})
            else:
                where = {"uri":{"$in":uris}}

        if where and len(where)>1:
            if "$and" not in where:
                cur_where = {"$and":[]}
            else:
                cur_where = {"$and":where["$and"]}
            for key in where:
                if key!="$and":
                    cur_where["$and"].append({key:where[key]})
            where = cur_where

        if where_document and len(where_document)>1:
            if "$and" not in where_document:
                cur_where_document = {"$and":[]}
            else:
                cur_where_document = {"$and":where_document["$and"]}
            for key in where_document:
                if key!="$and":
                    cur_where_document["$and"].append({key:where_document[key]})
            where_document = cur_where_document


        last_data = {}
        if is_persistent == None:
            client_data = self.client_collection.get(ids=ids,where=where,where_document=where_document,include=include)
            persistent_client_data = self.persistent_client_collection.get(ids=ids,where=where,where_document=where_document,include=include)
            last_data = deep_merge(client_data,persistent_client_data)
        elif is_persistent == True:
            persistent_client_data = self.persistent_client_collection.get(ids=ids,where=where,where_document=where_document,include=include)
            last_data = persistent_client_data
        elif is_persistent == False:
            client_data = self.client_collection.get(ids=ids,where=where,where_document=where_document,include=include)
            last_data = client_data

        return {"result":True,"ids":last_data.get("ids",[]),
                "documents":last_data.get("documents",[]),
                "metadatas":[json.dumps(metadata) for metadata in last_data.get("metadatas",[])],
                "embeddings":[{"embedding":embedding} for embedding in last_data.get("embeddings",[])]}
    
    async def S_C_GET_DOCUMENTS(self, client, syncId, data):
        return await self.main.send_service_request(client, syncId, data, self.S_C_GET_DOCUMENTS)

    async def C_S_GET_DOCUMENTS(self, client, syncId ,content):
        result_data = await self.get_documents(content)
        await self.S_C_GET_DOCUMENTS(client, syncId, result_data)

    async def query_documents(self, data):
        query_embeddings = data.get("query_embeddings",None)
        if query_embeddings != None:
            query_embeddings = query_embeddings.get("embedding",None)
        
        query_texts = data.get("query_texts",None)
        query_images = data.get("query_images",None)## TODO: Note that the image search function is not implemented
        query_uris = data.get("query_uris",None)
        n_results = data.get("n_results",10)

        where = data.get("where",None)
        where_document = data.get("where_document",None)
        include = data.get("include",["embeddings","metadatas", "documents","distances"])
        
        data_type = data.get("type",None)
        is_persistent = data.get("persistent",None)
        space = data.get("space",None)
        uris = data.get("uris",None)

        if where!=None:
            where = json.loads(where)

        if where_document!=None:
            where_document = json.loads(where_document)

        if data_type == None:
            pass
        elif data_type == "dynamic":
            if where:
                where = deep_merge(where,{"type":{"$eq":"dynamic"}})
            else:
                where = {"type":{"$eq":"dynamic"}}
        elif data_type == "static":
            if where:
                where = deep_merge(where,{"type":{"$eq":"static"}})
            else:
                where = {"type":{"$eq":"static"}}

        if space == None:
            pass
        else:
            if where:
                where = deep_merge(where,{"space":{"$eq":space}})
            else:
                where = {"space":{"$eq":space}}

        if uris == None:
            pass
        else:
            if where:
                where = deep_merge(where,{"uri":{"$in":uris}})
            else:
                where = {"uri":{"$in":uris}}

        if where and len(where)>1:
            if "$and" not in where:
                cur_where = {"$and":[]}
            else:
                cur_where = {"$and":where["$and"]}
            for key in where:
                if key!="$and":
                    cur_where["$and"].append({key:where[key]})
            where = cur_where

        if where_document and len(where_document)>1:
            if "$and" not in where_document:
                cur_where_document = {"$and":[]}
            else:
                cur_where_document = {"$and":where_document["$and"]}
            for key in where_document:
                if key!="$and":
                    cur_where_document["$and"].append({key:where_document[key]})
            where_document = cur_where_document

        last_data = {}
        if is_persistent == None:
            client_data = self.client_collection.query(query_embeddings=query_embeddings,
                                                       query_texts=query_texts,
                                                       query_images=query_images,
                                                       query_uris=query_uris,
                                                       where=where,where_document=where_document,
                                                       include=include,
                                                       n_results=n_results)
            
            persistent_client_data = self.persistent_client_collection.query(query_embeddings=query_embeddings,
                                                       query_texts=query_texts,
                                                       query_images=query_images,
                                                       query_uris=query_uris,
                                                       where=where,where_document=where_document,
                                                       include=include,
                                                       n_results=n_results)
            last_data = {}
            last_data["ids"] = []
            for i in range(len(client_data.get("ids",[]))):
                last_data["ids"].append(client_data.get("ids",[])[i] + persistent_client_data.get("ids",[])[i])

            last_data["documents"] = []
            for i in range(len(client_data.get("documents",[]))):
                last_data["documents"].append(client_data.get("documents",[])[i] + persistent_client_data.get("documents",[])[i])
            
            last_data["metadatas"] = []
            for i in range(len(client_data.get("metadatas",[]))):
                last_data["metadatas"].append(client_data.get("metadatas",[])[i] + persistent_client_data.get("metadatas",[])[i])
            
            last_data["embeddings"] = []
            for i in range(len(client_data.get("embeddings",[]))):
                last_data["embeddings"].append(client_data.get("embeddings",[])[i] + persistent_client_data.get("embeddings",[])[i])
            
            last_data["distances"] = []
            for i in range(len(client_data.get("distances",[]))):
                last_data["distances"].append(client_data.get("distances",[])[i] + persistent_client_data.get("distances",[])[i])

            result_data = {"ids":[],"documents":[],"metadatas":[],"embeddings":[],"distances":[]}
            for query_i in range(len(last_data.get("distances",[]))):
                cur_distance = last_data.get("distances",[])[query_i]
                indexed_arr = list(enumerate(cur_distance))
                sorted_arr = sorted(indexed_arr, key=lambda x: x[1])
                cur_ids = []
                result_data["ids"].append(cur_ids)
                cur_documents = []
                result_data["documents"].append(cur_documents)
                cur_metadatas = []
                result_data["metadatas"].append(cur_metadatas)
                cur_embeddings = []
                result_data["embeddings"].append(cur_embeddings)
                cur_distances = []
                result_data["distances"].append(cur_distances)
                for i in range(min(n_results,len(sorted_arr))):
                    cur_index = sorted_arr[i][0]
                    if cur_index < len(last_data.get("ids",[])[query_i]):
                        cur_ids.append(last_data.get("ids",[])[query_i][cur_index])
                    
                    if cur_index < len(last_data.get("documents",[])[query_i]):
                        cur_documents.append(last_data.get("documents",[])[query_i][cur_index])
                    
                    if cur_index < len(last_data.get("metadatas",[])[query_i]):
                        cur_metadatas.append(last_data.get("metadatas",[])[query_i][cur_index])

                    if cur_index < len(last_data.get("embeddings",[])[query_i]):
                        cur_embeddings.append(last_data.get("embeddings",[])[query_i][cur_index])
                    
                    if cur_index < len(last_data.get("distances",[])[query_i]):
                        cur_distances.append(last_data.get("distances",[])[query_i][cur_index])
            last_data = result_data
        elif is_persistent == True:
            persistent_client_data = self.persistent_client_collection.query(query_embeddings=query_embeddings,
                                                       query_texts=query_texts,
                                                       query_images=query_images,
                                                       query_uris=query_uris,
                                                       where=where,where_document=where_document,
                                                       include=include,
                                                       n_results=n_results)
            last_data = persistent_client_data
        elif is_persistent == False:
            client_data = self.client_collection.query(query_embeddings=query_embeddings,
                                                       query_texts=query_texts,
                                                       query_images=query_images,
                                                       query_uris=query_uris,
                                                       where=where,where_document=where_document,
                                                       include=include,
                                                       n_results=n_results)
            last_data = client_data



        cur_documents = []
        for i in range(len(last_data.get("documents",[]))):
            cur_documents.append({
                "ids":get_element(last_data.get("ids",[]),i,[]),
                "documents":get_element(last_data.get("documents",[]),i,[]),
                "metadatas":[json.dumps(metadata) for metadata in get_element(last_data.get("metadatas",[]),i,[])],
                "embeddings":[{"embedding":embedding} for embedding in get_element(last_data.get("embeddings",[]),i,[])],
                "distances":get_element(last_data.get("distances",[]),i,0),

            })
        finish_result_data = {"result":True,
            "query_documents":cur_documents}
        return finish_result_data


    async def S_C_QUERY_DOCUMENTS(self, client, syncId, data):
        return await self.main.send_service_request(client, syncId, data, self.S_C_QUERY_DOCUMENTS)

    ## Search for the most matching embedding
    async def C_S_QUERY_DOCUMENTS(self, client, syncId ,content):
        result_data = await self.query_documents(content)
        await self.S_C_QUERY_DOCUMENTS(client, syncId, result_data)



def deep_merge(dict1, dict2):
    result = copy.deepcopy(dict1)
    for key, value in dict2.items():
        if key in result:
            if isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = deep_merge(result[key], value)
            elif isinstance(result[key], list) and isinstance(value, list):
                result[key] = result[key] + value
            else:
                result[key] = value
        else:
            result[key] = value
    return result

def get_element(lst, index, default=None):
    try:
        return lst[index]
    except IndexError:
        return default