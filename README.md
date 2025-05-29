# 🧠 II-Agent + Jan.ai GGUF (локальний LLM) — Автоінсталятор з підтримкою CLI

Цей проєкт автоматизує запуск [II-Agent](https://github.com/Intelligent-Internet/ii-agent) із вбудованою підтримкою локального LLM-сервера [Jan.ai](https://github.com/janhq/jan), що працює з моделями у форматі `.gguf`. Інсталятор створює повністю налаштоване середовище на Windows у кілька кліків.

---

## 📦 Можливості

✅ Автоінсталяція II-Agent  
✅ Інтеграція Jan.ai (`/v1/completions` сумісність)  
✅ Підтримка `.gguf` моделей (через Jan сервер)  
✅ Створення ярлика на робочому столі  
✅ Без підключення до OpenAI або Anthropic  
✅ Працює повністю офлайн

---

## 📁 Структура

```
.
├─ ii-agent/                    # Клонований репозиторій II-Agent
│  └─ src/ii_agent/llm/jan_llm.py  # Адаптер до Jan.ai
├─ env/                         # Віртуальне середовище
├─ launch_ii-agent.bat          # Ярлик запуску
├─ install_env.bat              # Скрипт налаштування середовища
├─ install_script.iss           # Inno Setup скрипт
└─ ii-agent-jan-installer.exe   # Готовий .exe інсталятор
```

---

## 🚀 Як користуватись

### 🟢 Варіант 1: Готовий `.exe`

1. Завантажте [`ii-agent-jan-installer.exe`](./ii-agent-jan-installer.exe)  
2. Запустіть інсталятор  
3. Встановіть у бажану директорію  
4. Запустіть **ярлик "II-Agent CLI"** з робочого столу  

> ⚠️ Перед запуском переконайтесь, що **Jan.ai** уже запущений локально:  
> http://localhost:1337

---

### 🛠 Варіант 2: Ручна установка

```bash
git clone https://github.com/yourname/ii-agent-jan.git
cd ii-agent-jan
python -m venv env
env\Scripts\activate
cd ii-agent
pip install -r requirements.txt
```

Після чого `jan_llm.py` автоматично підключається до Jan.ai як LLM бекенд.

---

## ⚙️ Адаптер JanLLM (код)

Файл `src/ii_agent/llm/jan_llm.py` реалізує виклик до локального сервера Jan:

```python
import requests

class JanLLM:
    def __init__(self, host="http://localhost:1337", temperature=0.7, max_tokens=1024):
        self.api_url = f"{host}/v1/completions"
        self.temperature = temperature
        self.max_tokens = max_tokens

    def complete(self, prompt: str, stop: list = None):
        headers = {"Content-Type": "application/json"}
        payload = {
            "prompt": prompt,
            "temperature": self.temperature,
            "max_tokens": self.max_tokens,
            "stop": stop or []
        }
        response = requests.post(self.api_url, headers=headers, json=payload)
        if response.status_code == 200:
            return response.json().get("text", "").strip()
        else:
            raise Exception(f"JanAI API error: {response.text}")
```

---

## 🧠 Про Jan.ai

[Jan.ai](https://github.com/janhq/jan) — це локальний сервер LLM, який підтримує GGUF-моделі через [llama.cpp](https://github.com/ggerganov/llama.cpp). Він забезпечує `/v1/completions` сумісний інтерфейс для інтеграції з інструментами, такими як II-Agent.

---

## ❓Поширені питання

**Q:** Чи можу я використовувати свою GGUF модель?  
**A:** Так! Просто завантажте її в Jan.ai GUI або вказуйте через CLI.

**Q:** Чи потрібне інтернет-з'єднання?  
**A:** Ні. Все працює локально (Jan + II-Agent).

---

## 📄 Ліцензія

MIT для адаптера `jan_llm.py`. II-Agent — окремо ліцензований проєкт.

---

## 🤝 Автор

- Інтеграція Jan.ai у II-Agent: [METFARELL]  
- Підтримка української: 🇺🇦

---

## 🔧 Хочеш:

- Додати скріншоти GUI?  
- README українською?  
- Інструкції для Jan.ai в комплекті?  

**Пиши — допрацюю!**