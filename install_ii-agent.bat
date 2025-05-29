@echo off
title Встановлення II-Agent з вибором LLM
setlocal enabledelayedexpansion
chcp 65001 >nul

:: === 1. Перевірка Python ===
where python >nul 2>&1
if errorlevel 1 (
    echo [❌] Python не знайдено. Встановіть його: https://www.python.org/downloads/windows/
    pause
    exit /b
)

:: === 2. Перевірка Git ===
where git >nul 2>&1
if errorlevel 1 (
    echo [❌] Git не знайдено. Завантажити: https://git-scm.com/downloads
    pause
    exit /b
)

:: === 3. Вибір LLM ядра ===
echo.
echo ==== Оберіть LLM для II-Agent ====
echo [1] Jan.ai (локальний сервер на http://localhost:1337)
echo [2] Claude (Anthropic API)
echo [3] GPT4All / інше (налаштування вручну)
set /p choice="Ваш вибір [1-3]: "

if "%choice%"=="1" (
    set "LLM=jan"
) else if "%choice%"=="2" (
    set "LLM=claude"
) else (
    set "LLM=other"
)

:: === 4. Папка проєкту ===
cd /d D:\
if not exist II-Agent-Jan (
    mkdir II-Agent-Jan
)
cd II-Agent-Jan

:: === 5. Клонування репозиторію II-Agent ===
if not exist ii-agent (
    echo [🔄] Клонування II-Agent...
    git clone https://github.com/Intelligent-Internet/ii-agent.git
    if errorlevel 1 (
        echo [❌] Помилка при клонуванні!
        pause
        exit /b
    )
) else (
    echo [✔] Репозиторій вже існує. Пропускаємо клонування.
)

cd ii-agent || (
    echo [❌] Не знайдено папку ii-agent!
    pause
    exit /b
)

:: === 6. Створення віртуального середовища ===
cd ..
python -m venv env
call env\Scripts\activate
cd ii-agent

:: === 7. Встановлення залежностей (надійний метод) ===
echo [🔧] Встановлюємо базові залежності...
pip install -U pip setuptools wheel

echo [🔧] Встановлюємо залежності II-Agent вручну...
pip install requests pyyaml openai tiktoken anthropic prompt_toolkit || (
    echo [❌] Помилка при встановленні залежностей!
    pause
    exit /b
)

:: === 8. Jan.ai інтеграція ===
if "%LLM%"=="jan" (
    echo [➕] Додаємо адаптер Jan.ai...
    mkdir src\ii_agent\llm >nul 2>&1

    > src\ii_agent\llm\jan_llm.py (
    echo import requests
    echo.
    echo class JanLLM:
    echo.    def __init__(self, host="http://localhost:1337", temperature=0.7, max_tokens=1024):
    echo.        self.api_url = f"{host}/v1/completions"
    echo.        self.temperature = temperature
    echo.        self.max_tokens = max_tokens
    echo.
    echo.    def complete(self, prompt: str, stop: list = None):
    echo.        headers = {"Content-Type": "application/json"}
    echo.        payload = {
    echo.            "prompt": prompt,
    echo.            "temperature": self.temperature,
    echo.            "max_tokens": self.max_tokens,
    echo.            "stop": stop or []
    echo.        }
    echo.        response = requests.post(self.api_url, headers=headers, json=payload)
    echo.        if response.status_code == 200:
    echo.            return response.json().get("text", "").strip()
    echo.        else:
    echo.            raise Exception(f"JanAI API error: {response.text}")
    )

    powershell -Command "(Get-Content cli.py) -replace 'from src.ii_agent.llm.anthropic import ClaudeLLM', 'from src.ii_agent.llm.jan_llm import JanLLM' | Set-Content cli.py"
    powershell -Command "(Get-Content cli.py) -replace 'llm = ClaudeLLM.*', 'llm = JanLLM()' | Set-Content cli.py"
)

:: === 9. Створення файлу запуску
cd ..
> launch_ii-agent.bat (
    echo @echo off
    echo call env\Scripts\activate
    echo cd ii-agent
    echo python cli.py
)

:: === 10. Завершення
echo.
echo [✅] Установка завершена!
echo Запуск II-Agent: launch_ii-agent.bat
pause
exit /b
