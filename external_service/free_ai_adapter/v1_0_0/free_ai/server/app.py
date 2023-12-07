from fastapi import APIRouter
from pydantic import BaseModel, Field
from typing_extensions import TypedDict, Literal
from typing import Callable, Coroutine, Iterator, List, Optional, Tuple, Union, Dict
from starlette.concurrency import run_in_threadpool, iterate_in_threadpool

from fastapi import Depends, FastAPI, APIRouter, Request, Response, Body
import anyio
from anyio.streams.memory import MemoryObjectSendStream
from sse_starlette.sse import EventSourceResponse
import time
import string
import random
import json
from free_ai import MessageQueue,Message,MessageLevel,ProcessEngine
from functools import partial


app = FastAPI()

class ChatCompletionRequestMessage(BaseModel):
    role: Literal["system", "user", "assistant"] = Field(
        default="user", description="The role of the message."
    )
    content: str = Field(default="", description="The content of the message.")

stream_field = Field(
    default=False,
    description="Whether to stream the results as they are generated. Useful for chatbots.",
)
messages_level_field = Field(
    default=MessageLevel.MEDIUM,
    description="The level of the message.",
)

class CreateChatCompletionRequest(BaseModel):
    messages: List[ChatCompletionRequestMessage] = Field(
        default=[], description="A list of messages to generate completions for."
    )
    stream: bool = stream_field
    messages_level: MessageLevel = messages_level_field

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "messages": [
                        ChatCompletionRequestMessage(
                            role="system", content="You are a helpful assistant."
                        ).model_dump(),
                        ChatCompletionRequestMessage(
                            role="user", content="What is the capital of France?"
                        ).model_dump(),
                    ],
                    "stream": True,
                    "messages_level": 2,
                }
            ]
        }
    }

@app.post(
    "/v1/chat/completions",
)
async def create_chat_completion(
    request: Request,
    body: CreateChatCompletionRequest,
):
    now_message = Message(stream=body.stream, messages = body.model_dump()["messages"], level = body.messages_level)
    MessageQueue().push(now_message)
    await now_message.processed.wait()
    response = now_message.response
    completion_id = ''.join(random.choices(string.ascii_letters + string.digits, k=28))
    completion_timestamp = int(time.time())
    if not body.stream:
        response_text = ""
        try:
            async for chunk in response:
                response_text += chunk
        except Exception as e:
            now_message.have_error = True
            print("create_chat_completion Exception  ", e, response)
            pass
        finally:
            if response_text=="":
                now_message.have_error = True
            now_message.response_finished.set()
            return {
                'id': f'chatcmpl-{completion_id}',
                'object': 'chat.completion',
                'created': completion_timestamp,
                'model': "",
                'choices': [
                    {
                        'index': 0,
                        'message': {
                            'role': 'assistant',
                            'content': response_text,
                        },
                        'finish_reason': 'stop',
                    }
                ],
                'usage': {
                    'prompt_tokens': None,
                    'completion_tokens': None,
                    'total_tokens': None,
                },
            }

    async def streaming():
        have_one_chunk = False
        try:

            async for chunk in response:
                # if chunk.is_begins_with("<!DOCTYPE html>"):
                #     raise RuntimeError("ChatgptDemo: 403 Forbidden")
                # if chunk.is_begins_with("<script>"):
                #     raise RuntimeError("Solve challenge and pass cookies")
                # if "platform's risk control" in chunk:
                #     raise RuntimeError("Platform's Risk Control")

                have_one_chunk = True
                completion_data = {
                    'id': f'chatcmpl-{completion_id}',
                    'object': 'chat.completion.chunk',
                    'created': completion_timestamp,
                    'model': "",
                    'choices': [
                        {
                            'index': 0,
                            'delta': {
                                'content': chunk,
                            },
                            'finish_reason': None,
                        }
                    ],
                }
                content = json.dumps(completion_data, separators=(',', ':'))
                yield f'{content}'
                time.sleep(0.1)


            if have_one_chunk == False:
                raise RuntimeError("no response")
            
            end_completion_data: dict[str, Any] = {
                'id': f'chatcmpl-{completion_id}',
                'object': 'chat.completion.chunk',
                'created': completion_timestamp,
                'model': "",
                'choices': [
                    {
                        'index': 0,
                        'delta': {},
                        'finish_reason': 'stop',
                    }
                ],
            }
            content = json.dumps(end_completion_data, separators=(',', ':'))
            yield f'{content}'
        except Exception as e:
            now_message.have_error = True
            print("create_chat_completion Exception  ", e, response)
            pass
        finally:
            if have_one_chunk == False:
                now_message.have_error = True
            now_message.response_finished.set()

    send_chan, recv_chan = anyio.create_memory_object_stream(10)
    return EventSourceResponse(
        recv_chan,
        data_sender_callable=partial(  # type: ignore
            get_event_publisher,
            request=request,
            inner_send_chan=send_chan,
            iterator=streaming(),
        ),
    )


async def get_event_publisher(
    request: Request,
    inner_send_chan: MemoryObjectSendStream,
    iterator,
):
    async with inner_send_chan:
        try:
            async for chunk in iterator:
                await inner_send_chan.send(dict(data=chunk))
                if await request.is_disconnected():
                    raise anyio.get_cancelled_exc_class()()
            await inner_send_chan.send(dict(data="[DONE]"))
        except anyio.get_cancelled_exc_class() as e:
            with anyio.move_on_after(1, shield=True):
                raise e


class InitChat(BaseModel):
    proxy: Dict[str, str] | None = None
    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "proxy": {
                        "http": "",
                        "https": "",
                    },
                }
            ]
        }
    }


@app.post(
    "/v1/chat/init_completions",
)
async def init_chat_completion(
    init_chat: InitChat = None,
):
    cur_proxy = init_chat.proxy
    if cur_proxy:
        if "http" in cur_proxy:
            if cur_proxy["http"] == "" or cur_proxy["http"] == None:
                del cur_proxy["http"]
        if "https" in cur_proxy:
            if cur_proxy["https"] == "" or cur_proxy["https"] == None:
                del cur_proxy["https"]
    ProcessEngine().set_proxy(proxy=cur_proxy)
    return True