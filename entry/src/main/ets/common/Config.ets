/*
 * Copyright (c) 2025 Hunan OpenValley Digital Industry Development Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { Model, SystemModelsList } from "../interfaces"

// Vision models
const visionAllowedModels = [
  'llava',
  'moondream',
  'minicpm',
  'gemini-1\\.5',
  'gemini-2\\.0',
  'gemini-2\\.5',
  'gemini-exp',
  'claude-3',
  'claude-sonnet-4',
  'claude-opus-4',
  'vision',
  'glm-4v',
  'qwen-vl',
  'qwen2-vl',
  'qwen2.5-vl',
  'qwen2.5-omni',
  'qvq',
  'internvl2',
  'grok-vision-beta',
  'pixtral',
  'gpt-4(?:-[\\w-]+)',
  'gpt-4.1(?:-[\\w-]+)?',
  'gpt-4o(?:-[\\w-]+)?',
  'gpt-4.5(?:-[\\w-]+)',
  'chatgpt-4o(?:-[\\w-]+)?',
  'o1(?:-[\\w-]+)?',
  'o3(?:-[\\w-]+)?',
  'o4(?:-[\\w-]+)?',
  'deepseek-vl(?:[\\w-]+)?',
  'kimi-latest',
  'gemma-3(?:-[\\w-]+)',
  'doubao-seed-1[.-]6(?:-[\\w-]+)'
]

const visionExcludedModels = [
  'gpt-4-\\d+-preview',
  'gpt-4-turbo-preview',
  'gpt-4-32k',
  'gpt-4-\\d+',
  'o1-mini',
  'o3-mini',
  'o1-preview',
  'AIDC-AI/Marco-o1'
]
export const VISION_REGEX = new RegExp(
  `\\b(?!(?:${visionExcludedModels.join('|')})\\b)(${visionAllowedModels.join('|')})\\b`,
  'i'
)

// For middleware to identify models that must use the dedicated Image API
export const DEDICATED_IMAGE_MODELS = ['grok-2-image', 'dall-e-3', 'dall-e-2', 'gpt-image-1']
export const isDedicatedImageGenerationModel = (model: Model): boolean =>
DEDICATED_IMAGE_MODELS.filter((m) => model.id.includes(m)).length > 0

// Text to image models
export const TEXT_TO_IMAGE_REGEX = /flux|diffusion|stabilityai|sd-|dall|cogview|janus/i

// Reasoning models
export const REASONING_REGEX =
  /^(o\d+(?:-[\w-]+)?|.*\b(?:reasoning|reasoner|thinking)\b.*|.*-[rR]\d+.*|.*\bqwq(?:-[\w-]+)?\b.*|.*\bhunyuan-t1(?:-[\w-]+)?\b.*|.*\bglm-zero-preview\b.*|.*\bgrok-3-mini(?:-[\w-]+)?\b.*)$/i

// Embedding models
export const EMBEDDING_REGEX =
  /(?:^text-|embed|bge-|e5-|LLM2Vec|retrieval|uae-|gte-|jina-clip|jina-embeddings|voyage-)/i

// Rerank models
export const RERANKING_REGEX = /(?:rerank|re-rank|re-ranker|re-ranking|retrieval|retriever)/i

export const NOT_SUPPORTED_REGEX = /(?:^tts|whisper|speech)/i

// Tool calling models
export const FUNCTION_CALLING_MODELS = [
  'gpt-4o',
  'gpt-4o-mini',
  'gpt-4',
  'gpt-4.5',
  'o(1|3|4)(?:-[\\w-]+)?',
  'claude',
  'qwen',
  'qwen3',
  'hunyuan',
  'deepseek',
  'glm-4(?:-[\\w-]+)?',
  'learnlm(?:-[\\w-]+)?',
  'gemini(?:-[\\w-]+)?', // 提前排除了gemini的嵌入模型
  'grok-3(?:-[\\w-]+)?',
  'doubao-seed-1[.-]6(?:-[\\w-]+)?'
]

const FUNCTION_CALLING_EXCLUDED_MODELS = [
  'aqa(?:-[\\w-]+)?',
  'imagen(?:-[\\w-]+)?',
  'o1-mini',
  'o1-preview',
  'AIDC-AI/Marco-o1'
]

export const FUNCTION_CALLING_REGEX = new RegExp(
  `\\b(?!(?:${FUNCTION_CALLING_EXCLUDED_MODELS.join('|')})\\b)(?:${FUNCTION_CALLING_MODELS.join('|')})\\b`,
  'i'
)

export const CLAUDE_SUPPORTED_WEBSEARCH_REGEX = new RegExp(
  `\\b(?:claude-3(-|\\.)(7|5)-sonnet(?:-[\\w-]+)|claude-3(-|\\.)5-haiku(?:-[\\w-]+)|claude-sonnet-4(?:-[\\w-]+)?|claude-opus-4(?:-[\\w-]+)?)\\b`,
  'i'
)

export function isFunctionCallingModel(model: Model): boolean {
  if (model.type?.includes('function_calling')) {
    return true
  }

  if (isEmbeddingModel(model)) {
    return false
  }

  if (model.provider === 'qiniu') {
    return ['deepseek-v3-tool', 'deepseek-v3-0324', 'qwq-32b', 'qwen2.5-72b-instruct'].includes(model.id)
  }

  if (['deepseek', 'anthropic'].includes(model.provider)) {
    return true
  }

  return FUNCTION_CALLING_REGEX.test(model.id)
}

export const SYSTEM_MODELS: SystemModelsList = {
  defaultModel: [
    {
      // 默认助手模型
      id: 'deepseek-ai/DeepSeek-V3',
      name: 'deepseek-ai/DeepSeek-V3',
      provider: 'silicon',
      group: 'deepseek-ai',
    },
    {
      // 默认话题命名模型
      id: 'Qwen/Qwen3-8B',
      name: 'Qwen/Qwen3-8B',
      provider: 'silicon',
      group: 'Qwen'
    },
    {
      // 默认翻译模型
      id: 'deepseek-ai/DeepSeek-V3',
      name: 'deepseek-ai/DeepSeek-V3',
      provider: 'silicon',
      group: 'deepseek-ai'
    },
    {
      // 默认快捷助手模型
      id: 'deepseek-ai/DeepSeek-V3',
      name: 'deepseek-ai/DeepSeek-V3',
      provider: 'silicon',
      group: 'deepseek-ai'
    }
  ],
  o3: [
    {
      id: 'gpt-4o',
      provider: 'o3',
      name: 'GPT-4o',
      group: 'OpenAI'
    },
    {
      id: 'o1-mini',
      provider: 'o3',
      name: 'o1-mini',
      group: 'OpenAI'
    },
    {
      id: 'o1-preview',
      provider: 'o3',
      name: 'o1-preview',
      group: 'OpenAI'
    },
    {
      id: 'o3-mini',
      provider: 'o3',
      name: 'o3-mini',
      group: 'OpenAI'
    },
    {
      id: 'o3-mini-high',
      provider: 'o3',
      name: 'o3-mini-high',
      group: 'OpenAI'
    },
    {
      id: 'claude-3-7-sonnet-20250219',
      provider: 'o3',
      name: 'claude-3-7-sonnet-20250219',
      group: 'Anthropic'
    },
    {
      id: 'claude-3-5-sonnet-20241022',
      provider: 'o3',
      name: 'claude-3-5-sonnet-20241022',
      group: 'Anthropic'
    },
    {
      id: 'claude-3-5-haiku-20241022',
      provider: 'o3',
      name: 'claude-3-5-haiku-20241022',
      group: 'Anthropic'
    },
    {
      id: 'claude-3-opus-20240229',
      provider: 'o3',
      name: 'claude-3-opus-20240229',
      group: 'Anthropic'
    },
    {
      id: 'claude-3-haiku-20240307',
      provider: 'o3',
      name: 'claude-3-haiku-20240307',
      group: 'Anthropic'
    },
    {
      id: 'claude-3-5-sonnet-20240620',
      provider: 'o3',
      name: 'claude-3-5-sonnet-20240620',
      group: 'Anthropic'
    },
    {
      id: 'deepseek-ai/Deepseek-R1',
      provider: 'o3',
      name: 'DeepSeek R1',
      group: 'DeepSeek'
    },
    {
      id: 'deepseek-reasoner',
      provider: 'o3',
      name: 'deepseek-reasoner',
      group: 'DeepSeek'
    },
    {
      id: 'deepseek-chat',
      provider: 'o3',
      name: 'deepseek-chat',
      group: 'DeepSeek'
    },
    {
      id: 'deepseek-ai/DeepSeek-V3',
      provider: 'o3',
      name: 'DeepSeek V3',
      group: 'DeepSeek'
    },
    {
      id: 'text-embedding-3-small',
      provider: 'o3',
      name: 'text-embedding-3-small',
      group: '嵌入模型'
    },
    {
      id: 'text-embedding-ada-002',
      provider: 'o3',
      name: 'text-embedding-ada-002',
      group: '嵌入模型'
    },
    {
      id: 'text-embedding-v2',
      provider: 'o3',
      name: 'text-embedding-v2',
      group: '嵌入模型'
    },
    {
      id: 'Doubao-embedding',
      provider: 'o3',
      name: 'Doubao-embedding',
      group: '嵌入模型'
    },
    {
      id: 'Doubao-embedding-large',
      provider: 'o3',
      name: 'Doubao-embedding-large',
      group: '嵌入模型'
    }
  ],
  ollama: [],
  lmstudio: [],
  silicon: [
    {
      id: 'deepseek-ai/DeepSeek-R1',
      name: 'deepseek-ai/DeepSeek-R1',
      provider: 'silicon',
      group: 'deepseek-ai'
    },
    {
      id: 'deepseek-ai/DeepSeek-V3',
      name: 'deepseek-ai/DeepSeek-V3',
      provider: 'silicon',
      group: 'deepseek-ai'
    },
    {
      id: 'Qwen/Qwen2.5-7B-Instruct',
      provider: 'silicon',
      name: 'Qwen2.5-7B-Instruct',
      group: 'Qwen'
    },
    {
      id: 'BAAI/bge-m3',
      name: 'BAAI/bge-m3',
      provider: 'silicon',
      group: 'BAAI'
    },
    {
      id: 'Qwen/Qwen3-8B',
      name: 'Qwen/Qwen3-8B',
      provider: 'silicon',
      group: 'Qwen'
    }
  ],
  openai: [
    { id: 'gpt-4.5-preview', provider: 'openai', name: ' gpt-4.5-preview', group: 'gpt-4.5' },
    { id: 'gpt-4o', provider: 'openai', name: ' GPT-4o', group: 'GPT 4o' },
    { id: 'gpt-4o-mini', provider: 'openai', name: ' GPT-4o-mini', group: 'GPT 4o' },
    { id: 'o1-mini', provider: 'openai', name: ' o1-mini', group: 'o1' },
    { id: 'o1-preview', provider: 'openai', name: ' o1-preview', group: 'o1' }
  ],
  giteeai: [],
  deepseek: [
    {
      id: 'deepseek-chat',
      provider: 'deepseek',
      name: 'DeepSeek Chat',
      group: 'DeepSeek Chat'
    },
    {
      id: 'deepseek-reasoner',
      provider: 'deepseek',
      name: 'DeepSeek Reasoner',
      group: 'DeepSeek Reasoner'
    }
  ],
  github: [
    {
      id: 'gpt-4o',
      provider: 'github',
      name: 'OpenAI GPT-4o',
      group: 'OpenAI'
    }
  ],
  copilot: [
    {
      id: 'gpt-4o-mini',
      provider: 'copilot',
      name: 'OpenAI GPT-4o-mini',
      group: 'OpenAI'
    }
  ],
  modelscope: [
    {
      id: 'Qwen/Qwen2.5-72B-Instruct',
      name: 'Qwen/Qwen2.5-72B-Instruct',
      provider: 'modelscope',
      group: 'Qwen'
    },
    {
      id: 'Qwen/Qwen2.5-VL-72B-Instruct',
      name: 'Qwen/Qwen2.5-VL-72B-Instruct',
      provider: 'modelscope',
      group: 'Qwen'
    },
    {
      id: 'Qwen/Qwen2.5-Coder-32B-Instruct',
      name: 'Qwen/Qwen2.5-Coder-32B-Instruct',
      provider: 'modelscope',
      group: 'Qwen'
    },
    {
      id: 'deepseek-ai/DeepSeek-R1',
      name: 'deepseek-ai/DeepSeek-R1',
      provider: 'modelscope',
      group: 'deepseek-ai'
    },
    {
      id: 'deepseek-ai/DeepSeek-V3',
      name: 'deepseek-ai/DeepSeek-V3',
      provider: 'modelscope',
      group: 'deepseek-ai'
    }
  ],
  doubao: [
    {
      id: 'doubao-1-5-vision-pro-32k-250115',
      provider: 'doubao',
      name: 'doubao-1.5-vision-pro',
      group: 'Doubao-1.5-vision-pro'
    },
    {
      id: 'doubao-1-5-pro-32k-250115',
      provider: 'doubao',
      name: 'doubao-1.5-pro-32k',
      group: 'Doubao-1.5-pro'
    },
    {
      id: 'doubao-1-5-pro-32k-character-250228',
      provider: 'doubao',
      name: 'doubao-1.5-pro-32k-character',
      group: 'Doubao-1.5-pro'
    },
    {
      id: 'doubao-1-5-pro-256k-250115',
      provider: 'doubao',
      name: 'Doubao-1.5-pro-256k',
      group: 'Doubao-1.5-pro'
    },
    {
      id: 'deepseek-r1-250120',
      provider: 'doubao',
      name: 'DeepSeek-R1',
      group: 'DeepSeek'
    },
    {
      id: 'deepseek-r1-distill-qwen-32b-250120',
      provider: 'doubao',
      name: 'DeepSeek-R1-Distill-Qwen-32B',
      group: 'DeepSeek'
    },
    {
      id: 'deepseek-r1-distill-qwen-7b-250120',
      provider: 'doubao',
      name: 'DeepSeek-R1-Distill-Qwen-7B',
      group: 'DeepSeek'
    },
    {
      id: 'deepseek-v3-250324',
      provider: 'doubao',
      name: 'DeepSeek-V3',
      group: 'DeepSeek'
    },
    {
      id: 'deepseek-v3-250324',
      provider: 'doubao',
      name: 'DeepSeek-V3',
      group: 'DeepSeek'
    },
    {
      id: 'doubao-pro-32k-241215',
      provider: 'doubao',
      name: 'Doubao-pro-32k',
      group: 'Doubao-pro'
    },
    {
      id: 'doubao-pro-32k-functioncall-241028',
      provider: 'doubao',
      name: 'Doubao-pro-32k-functioncall-241028',
      group: 'Doubao-pro'
    },
    {
      id: 'doubao-pro-32k-character-241215',
      provider: 'doubao',
      name: 'Doubao-pro-32k-character-241215',
      group: 'Doubao-pro'
    },
    {
      id: 'doubao-pro-256k-241115',
      provider: 'doubao',
      name: 'Doubao-pro-256k',
      group: 'Doubao-pro'
    },
    {
      id: 'doubao-lite-4k-character-240828',
      provider: 'doubao',
      name: 'Doubao-lite-4k-character-240828',
      group: 'Doubao-lite'
    },
    {
      id: 'doubao-lite-32k-240828',
      provider: 'doubao',
      name: 'Doubao-lite-32k',
      group: 'Doubao-lite'
    },
    {
      id: 'doubao-lite-32k-character-241015',
      provider: 'doubao',
      name: 'Doubao-lite-32k-character-241015',
      group: 'Doubao-lite'
    },
    {
      id: 'doubao-lite-128k-240828',
      provider: 'doubao',
      name: 'Doubao-lite-128k',
      group: 'Doubao-lite'
    },
    {
      id: 'doubao-1-5-lite-32k-250115',
      provider: 'doubao',
      name: 'Doubao-1.5-lite-32k',
      group: 'Doubao-lite'
    },
    {
      id: 'doubao-embedding-large-text-240915',
      provider: 'doubao',
      name: 'Doubao-embedding-large',
      group: 'Doubao-embedding'
    },
    {
      id: 'doubao-embedding-text-240715',
      provider: 'doubao',
      name: 'Doubao-embedding',
      group: 'Doubao-embedding'
    },
    {
      id: 'doubao-embedding-vision-241215',
      provider: 'doubao',
      name: 'Doubao-embedding-vision',
      group: 'Doubao-embedding'
    },
    {
      id: 'doubao-vision-lite-32k-241015',
      provider: 'doubao',
      name: 'Doubao-vision-lite-32k',
      group: 'Doubao-vision-lite-32k'
    }
  ],
  nvidia: [
    {
      id: '01-ai/yi-large',
      provider: 'nvidia',
      name: 'yi-large',
      group: 'Yi'
    },
    {
      id: 'meta/llama-3.1-405b-instruct',
      provider: 'nvidia',
      name: 'llama-3.1-405b-instruct',
      group: 'llama-3.1'
    }
  ]
}

export function isVisionModel(model: Model): boolean {
  if (!model) {
    return false
  }
  // 新添字段 copilot-vision-request 后可使用 vision
  // if (model.provider === 'copilot') {
  //   return false
  // }

  if (model.provider === 'doubao') {
    return VISION_REGEX.test(model.name) || VISION_REGEX.test(model.id) || model.type?.includes('vision') || false
  }

  return VISION_REGEX.test(model.id) || model.type?.includes('vision') || false
}

export function isEmbeddingModel(model: Model): boolean {
  if (!model) {
    return false
  }

  if (['anthropic'].includes(model?.provider)) {
    return false
  }

  if (model.provider === 'doubao') {
    return EMBEDDING_REGEX.test(model.name)
  }

  if (isRerankModel(model)) {
    return false
  }

  return EMBEDDING_REGEX.test(model.id) || model.type?.includes('embedding') || false
}

export function isRerankModel(model: Model): boolean {
  return model ? RERANKING_REGEX.test(model.id) || false : false
}