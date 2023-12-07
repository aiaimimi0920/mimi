from __future__  import annotations
from dataclasses import dataclass
from .provider   import BaseProvider
from .provider   import (
    Aivvm,
    Bard,
    ChatForAi,
    ChatgptAi,
    ChatgptDemo,
    ChatgptDuo,
    DeepAi,
    FreeGpt,
    GptGo,
    H2o,
    LeptonAi,
    OpenaiChat,
    Phind,
    PiAi,
    Vercel,
    # Ylokh,
    You,
    Yqcloud
)

@dataclass(unsafe_hash=True)
class Model:
    name: str
    base_provider: str
    best_provider: type[BaseProvider] = None

default = Model(
    name          = "",
    base_provider = "",
    best_provider = OpenaiChat
)

# GPT-3.5 too, but all providers supports long responses and a custom timeouts
gpt_35_long = Model(
    name          = 'gpt-3.5-turbo',
    base_provider = 'openai',
    best_provider = OpenaiChat
)

# GPT-3.5 / GPT-4
gpt_35_turbo = Model(
    name          = 'gpt-3.5-turbo',
    base_provider = 'openai',
    best_provider = OpenaiChat
)

gpt_4 = Model(
    name          = 'gpt-4',
    base_provider = 'openai',
    best_provider = Aivvm
)

# Bard
palm = Model(
    name          = 'palm',
    base_provider = 'google',
    best_provider = Bard)

# H2o
llama_7b = Model(
    name          = 'h2oai/h2ogpt-4096-llama2-7b-chat',
    base_provider = 'huggingface',
    best_provider = H2o)

llama_13b = Model(
    name          = 'h2oai/h2ogpt-4096-llama2-13b-chat',
    base_provider = 'huggingface',
    best_provider = H2o)

llama_70b = Model(
    name          = 'h2oai/h2ogpt-4096-llama2-70b-chat',
    base_provider = 'huggingface',
    best_provider = H2o)

codellama_34b = Model(
    name          = 'h2oai/h2ogpt-16k-codellama-34b-instruct',
    base_provider = 'huggingface',
    best_provider = H2o)


# Vercel
command_light_nightly = Model(
    name          = 'command-light-nightly',
    base_provider = 'cohere',
    best_provider = Vercel)

command_nightly = Model(
    name          = 'command-nightly',
    base_provider = 'cohere',
    best_provider = Vercel)

gpt_neox_20b = Model(
    name          = 'EleutherAI/gpt-neox-20b',
    base_provider = 'huggingface',
    best_provider = Vercel)

oasst_sft_1_pythia_12b = Model(
    name          = 'OpenAssistant/oasst-sft-1-pythia-12b',
    base_provider = 'huggingface',
    best_provider = Vercel)

oasst_sft_4_pythia_12b_epoch_35 = Model(
    name          = 'OpenAssistant/oasst-sft-4-pythia-12b-epoch-3.5',
    base_provider = 'huggingface',
    best_provider = Vercel)

santacoder = Model(
    name          = 'bigcode/santacoder',
    base_provider = 'huggingface',
    best_provider = Vercel)

bloom = Model(
    name          = 'bigscience/bloom',
    base_provider = 'huggingface',
    best_provider = Vercel)

flan_t5_xxl = Model(
    name          = 'google/flan-t5-xxl',
    base_provider = 'huggingface',
    best_provider = Vercel)

gpt_35_turbo_16k = Model(
    name          = 'gpt-3.5-turbo-16k',
    base_provider = 'openai',
    best_provider = Vercel)

gpt_35_turbo_16k_0613 = Model(
    name          = 'gpt-3.5-turbo-16k-0613',
    base_provider = 'openai',
    best_provider = Vercel)

gpt_35_turbo_0613 = Model(
    name          = 'gpt-3.5-turbo-0613',
    base_provider = 'openai',
    best_provider= LeptonAi
)

gpt_4_0613 = Model(
    name          = 'gpt-4-0613',
    base_provider = 'openai',
    best_provider = LeptonAi)

gpt_4_32k = Model(
    name          = 'gpt-4-32k',
    base_provider = 'openai',
    best_provider = LeptonAi)

gpt_4_32k_0613 = Model(
    name          = 'gpt-4-32k-0613',
    base_provider = 'openai',
    best_provider = LeptonAi)

text_ada_001 = Model(
    name          = 'text-ada-001',
    base_provider = 'openai',
    best_provider = Vercel)

text_babbage_001 = Model(
    name          = 'text-babbage-001',
    base_provider = 'openai',
    best_provider = Vercel)

text_curie_001 = Model(
    name          = 'text-curie-001',
    base_provider = 'openai',
    best_provider = Vercel)

text_davinci_002 = Model(
    name          = 'text-davinci-002',
    base_provider = 'openai',
    best_provider = Vercel)

text_davinci_003 = Model(
    name          = 'text-davinci-003',
    base_provider = 'openai',
    best_provider = Vercel)

llama70b_v2_chat = Model(
    name          = 'replicate:a16z-infra/llama70b-v2-chat',
    base_provider = 'replicate',
    best_provider = Vercel)

llama13b_v2_chat = Model(
    name          = 'replicate:a16z-infra/llama13b-v2-chat',
    base_provider = 'replicate',
    best_provider = Vercel)

llama7b_v2_chat = Model(
    name          = 'replicate:a16z-infra/llama7b-v2-chat',
    base_provider = 'replicate',
    best_provider = Vercel)


class ModelUtils:
    convert: dict[str, Model] = {
        # gpt-3.5
        'gpt-3.5-turbo'          : gpt_35_turbo,
        'gpt-3.5-turbo-0613'     : gpt_35_turbo_0613,
        'gpt-3.5-turbo-16k'      : gpt_35_turbo_16k,
        'gpt-3.5-turbo-16k-0613' : gpt_35_turbo_16k_0613,
        
        # gpt-4
        'gpt-4'          : gpt_4,
        'gpt-4-0613'     : gpt_4_0613,
        'gpt-4-32k'      : gpt_4_32k,
        'gpt-4-32k-0613' : gpt_4_32k_0613,
        
        # Bard
        'palm2'       : palm,
        'palm'        : palm,
        'google'      : palm,
        'google-bard' : palm,
        'google-palm' : palm,
        'bard'        : palm,
        
        # H2o
        'llama_7b'  : llama_7b,
        'llama-13b'  : llama_13b,
        'llama_70b'  : llama_70b,
        'codellama_34b'  : codellama_34b,
        
        # Vercel
        'command-nightly'   : command_nightly,
        'gpt-neox-20b'      : gpt_neox_20b,
        'santacoder'        : santacoder,
        'bloom'             : bloom,
        'flan-t5-xxl'       : flan_t5_xxl,
        'text-ada-001'      : text_ada_001,
        'text-babbage-001'  : text_babbage_001,
        'text-curie-001'    : text_curie_001,
        'text-davinci-002'  : text_davinci_002,
        'text-davinci-003'  : text_davinci_003,
        'llama13b-v2-chat'  : llama13b_v2_chat,
        'llama7b-v2-chat'   : llama7b_v2_chat,
        
        'oasst-sft-1-pythia-12b'           : oasst_sft_1_pythia_12b,
        'oasst-sft-4-pythia-12b-epoch-3.5' : oasst_sft_4_pythia_12b_epoch_35,
        'command-light-nightly'            : command_light_nightly,
    }

