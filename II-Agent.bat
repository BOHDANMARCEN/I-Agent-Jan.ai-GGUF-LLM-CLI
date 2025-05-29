@echo off
title Встановлення II-Agent з вибором LLM
setlocal enabledelayedexpansion
chcp 65001 >nul

echo [INFO] Початок встановлення II-Agent...
echo.

:: === 0. Змінні ===
set "PROJECT_BASE_DIR=%cd%"
set "PROJECT_NAME=II-Agent-Setup"
set "PROJECT_DIR=%PROJECT_BASE_DIR%\%PROJECT_NAME%"
set "VENV_NAME=env"

:: === 1. Перевірка Python ===
echo [INFO] Перевірка наявності Python...
where python >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python не знайдено. Будь ласка, встановіть Python 3.8+ з https://www.python.org/downloads/windows/
    echo [HINT]  Переконайтеся, що Python додано до PATH під час встановлення.
    pause
    exit /b 1
)
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo [SUCCESS] Python знайдено (Версія: %PYTHON_VERSION%).
echo.

:: === 2. Перевірка Git ===
echo [INFO] Перевірка наявності Git...
where git >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git не знайдено. Будь ласка, завантажте та встановіть Git з https://git-scm.com/downloads
    echo [HINT]  Переконайтеся, що Git додано до PATH під час встановлення.
    pause
    exit /b 1
)
echo [SUCCESS] Git знайдено.
echo.

:: === 3. Вибір LLM ядра ===
:CHOOSE_LLM
echo ==== Оберіть LLM для II-Agent ====
echo [1] Jan.ai (локальний сервер, типово на http://localhost:1337)
echo [2] Claude (Anthropic API, потребує ANTHROPIC_API_KEY)
echo [3] GPT4All / інше (потребує ручного налаштування `cli.py`)
echo.
set /p choice="Ваш вибір [1-3]: "

set "LLM_SETUP_INSTRUCTIONS="
if "%choice%"=="1" (
    set "LLM_TYPE=jan"
    set "LLM_NAME=Jan.ai"
    set "LLM_SETUP_INSTRUCTIONS=УВАГА: Переконайтеся, що локальний сервер Jan.ai ЗАПУЩЕНО (зазвичай на http://localhost:1337) перед запуском агента."
) else if "%choice%"=="2" (
    set "LLM_TYPE=claude"
    set "LLM_NAME=Claude (Anthropic)"
    set "LLM_SETUP_INSTRUCTIONS=УВАГА: Переконайтеся, що змінна середовища ANTHROPIC_API_KEY встановлена з вашим дійсним ключем API."
) else if "%choice%"=="3" (
    set "LLM_TYPE=other"
    set "LLM_NAME=GPT4All / Інший"
    set "LLM_SETUP_INSTRUCTIONS=УВАГА: Вам потрібно буде вручну налаштувати конфігурацію LLM у файлі 'ii-agent\cli.py' або відповідних файлах."
) else (
    echo [WARNING] Невірний вибір. Будь ласка, введіть число від 1 до 3.
    goto CHOOSE_LLM
)
echo [INFO] Ви обрали: %LLM_NAME%.
if defined LLM_SETUP_INSTRUCTIONS echo [INFO] %LLM_SETUP_INSTRUCTIONS%
echo.

:: === 4. Створення папки проєкту ===
echo [INFO] Налаштування папки проєкту: %PROJECT_DIR%
if not exist "%PROJECT_DIR%" (
    mkdir "%PROJECT_DIR%"
    if errorlevel 1 (
        echo [ERROR] Не вдалося створити папку проєкту: %PROJECT_DIR%
        pause
        exit /b 1
    )
    echo [SUCCESS] Папку проєкту створено.
) else (
    echo [INFO] Папка проєкту вже існує.
)
cd /d "%PROJECT_DIR%"

:: === 5. Клонування/оновлення репозиторію II-Agent ===
if not exist "ii-agent\.git" (
    echo [INFO] Клонування репозиторію II-Agent...
    git clone https://github.com/Intelligent-Internet/ii-agent.git
    if errorlevel 1 (
        echo [ERROR] Помилка під час клонування репозиторію II-Agent!
        pause
        exit /b 1
    )
    echo [SUCCESS] Репозиторій успішно склоновано.
) else (
    echo [INFO] Репозиторій ii-agent вже існує. Спроба оновлення...
    cd ii-agent
    git pull
    cd ..
    echo [INFO] Репозиторій оновлено (або вже актуальний).
)
echo.

:: === 6. Створення та активація віртуального середовища ===
echo [INFO] Налаштування віртуального середовища Python (%VENV_NAME%)...
if not exist "%VENV_NAME%\Scripts\activate.bat" (
    echo [INFO] Створення віртуального середовища...
    python -m venv %VENV_NAME%
    if errorlevel 1 (
        echo [ERROR] Не вдалося створити віртуальне середовище!
        pause
        exit /b 1
    )
    echo [SUCCESS] Віртуальне середовище створено.
) else (
    echo [INFO] Віртуальне середовище вже існує.
)

echo [INFO] Активація віртуального середовища...
call "%VENV_NAME%\Scripts\activate.bat"
if errorlevel 1 (
    echo [ERROR] Не вдалося активувати віртуальне середовище!
    pause
    exit /b 1
)
echo [SUCCESS] Віртуальне середовище активовано.
echo.

:: === 7. Встановлення залежностей ===
echo [INFO] Перехід до папки ii-agent для встановлення залежностей...
cd ii-agent
if not exist "requirements.txt" (
    echo [ERROR] Файл requirements.txt не знайдено в папці ii-agent!
    pause
    exit /b 1
)

echo [INFO] Встановлення залежностей з requirements.txt...
pip install -r requirements.txt
if errorlevel 1 (
    echo [ERROR] Помилка під час встановлення залежностей! Перевірте вивід вище.
    pause
    exit /b 1
)
echo [SUCCESS] Залежності успішно встановлено.
echo.

:: === 8. Інтеграція обраного LLM ===
if "%LLM_TYPE%"=="jan" (
    echo [INFO] Налаштування інтеграції з Jan.ai...
    set "LLM_ADAPTER_DIR=src\ii_agent\llm"
    if not exist "%LLM_ADAPTER_DIR%" (
        mkdir "%LLM_ADAPTER_DIR%"
        if errorlevel 1 (
            echo [ERROR] Не вдалося створити папку для адаптера LLM: %LLM_ADAPTER_DIR%
            pause
            exit /b 1
        )
    )

    echo [INFO] Створення файлу адаптера jan_llm.py...
    (
        echo import requests
        echo import json
        echo.
        echo class JanLLM:
        echo.    def __init__(self, host="http://localhost:1337", model=None, temperature=0.7, max_tokens=2048, top_p=0.95, top_k=40, stream=False):
        echo.        self.api_url = f"{host}/v1/chat/completions" # Jan.ai частіше використовує chat/completions
        echo.        self.model = model # Модель може бути вказана в Jan.ai UI або тут
        echo.        self.temperature = temperature
        echo.        self.max_tokens = max_tokens
        echo.        self.top_p = top_p
        echo.        self.top_k = top_k
        echo.        self.stream = stream # Поки що не використовується в ii-agent, але для повноти
        echo.
        echo.    def complete(self, prompt: str, stop: list = None, system_message: str = None):
        echo.        headers = {"Content-Type": "application/json"}
        echo.        messages = []
        echo.        if system_message:
        echo.            messages.append({"role": "system", "content": system_message})
        echo.        messages.append({"role": "user", "content": prompt})
        echo.
        echo.        payload = {
        echo.            "model": self.model, # Деякі сервери Jan.ai можуть вимагати це
        echo.            "messages": messages,
        echo.            "temperature": self.temperature,
        echo.            "max_tokens": self.max_tokens,
        echo.            "top_p": self.top_p,
        echo.            "top_k": self.top_k,
        echo.            "stream": self.stream
        echo.        }
        echo.        if stop: # Додаємо stop тільки якщо він є, інакше деякі сервери можуть видати помилку
        echo.            payload["stop"] = stop
        echo.
        echo.        try:
        echo.            response = requests.post(self.api_url, headers=headers, json=payload, timeout=180) # Збільшено timeout
        echo.            response.raise_for_status()  # Викине HTTPError для поганих відповідей (4xx or 5xx)
        echo.            data = response.json()
        echo.            if "choices" in data and len(data["choices"]) > 0:
        echo.                # Для /v1/chat/completions відповідь знаходиться в 'message.content'
        echo.                content = data["choices"][0].get("message", {}).get("content", "")
        echo.                if not content and "text" in data["choices"][0]: # Запасний варіант для старих API /v1/completions
        echo.                     content = data["choices"][0].get("text", "")
        echo.                return content.strip()
        echo.            else:
        echo.                # print(f"[DEBUG] JanAI неочікувана структура відповіді: {data}") # Для відладки
        echo.                raise Exception(f"JanAI API Error: 'choices' not found or empty in response. Full response: {data}")
        echo.        except requests.exceptions.Timeout:
        echo.            raise Exception(f"JanAI API Error: Запит перевищив час очікування ({180}s) до {self.api_url}")
        echo.        except requests.exceptions.RequestException as e:
        echo.            raise Exception(f"JanAI API Error: Помилка запиту: {e}. URL: {self.api_url}")
        echo.        except json.JSONDecodeError as e:
        echo.            raise Exception(f"JanAI API Error: Помилка декодування JSON. Status: {response.status_code}. Response: {response.text[:500]}...")
        echo.        except (KeyError, IndexError) as e:
        echo.            raise Exception(f"JanAI API Error: Неочікуваний формат відповіді (відсутній ключ {e}). Data: {data}")
    ) > "%LLM_ADAPTER_DIR%\jan_llm.py"
    if errorlevel 1 (
        echo [ERROR] Не вдалося створити файл адаптера jan_llm.py!
        pause
        exit /b 1
    )
    echo [SUCCESS] Файл адаптера jan_llm.py створено.

    echo [INFO] Модифікація cli.py для використання JanLLM...
    if not exist "cli.py" (
        echo [ERROR] Файл cli.py не знайдено! Неможливо продовжити інтеграцію Jan.ai.
        pause
        exit /b 1
    )
    :: Використовуємо PowerShell для надійнішої заміни тексту
    powershell -Command "(Get-Content cli.py -Raw) -replace 'from src.ii_agent.llm.anthropic import ClaudeLLM', 'from src.ii_agent.llm.jan_llm import JanLLM' | Set-Content cli.py -Encoding UTF8"
    powershell -Command "(Get-Content cli.py -Raw) -replace 'llm = ClaudeLLM\(api_key=os.getenv\(''ANTHROPIC_API_KEY''\)\)', 'llm = JanLLM()' | Set-Content cli.py -Encoding UTF8"
    :: Альтернативна заміна, якщо ClaudeLLM ініціалізується без аргументів у cli.py
    powershell -Command "(Get-Content cli.py -Raw) -replace 'llm = ClaudeLLM\(\)', 'llm = JanLLM()' | Set-Content cli.py -Encoding UTF8"
    
    echo [SUCCESS] cli.py модифіковано для використання JanLLM.
    echo.
) else if "%LLM_TYPE%"=="claude" (
    echo [INFO] Для Claude (Anthropic) використовується стандартна конфігурація ii-agent.
    echo [INFO] %LLM_SETUP_INSTRUCTIONS%
    echo.
) else if "%LLM_TYPE%"=="other" (
    echo [INFO] Для %LLM_NAME% вам потрібно налаштувати ii-agent вручну.
    echo [INFO] %LLM_SETUP_INSTRUCTIONS%
    echo.
)
cd ..
:: Повертаємось до PROJECT_DIR

:: === 9. Створення файлу запуску ===
echo [INFO] Створення файлу запуску launch_ii-agent.bat...
(
    echo @echo off
    echo title II-Agent Launcher (%LLM_NAME%)
    echo echo Активуємо віртуальне середовище...
    echo call "%VENV_NAME%\Scripts\activate.bat"
    echo.
    echo echo Переходимо до папки агента...
    echo cd ii-agent
    echo.
    if defined LLM_SETUP_INSTRUCTIONS (
        echo echo Нагадування: %LLM_SETUP_INSTRUCTIONS%
        echo echo.
    )
    echo echo Запуск II-Agent CLI...
    echo python cli.py %*
    echo.
    echo echo Натисніть будь-яку клавішу для закриття цього вікна запуску...
    echo pause ^>nul
) > "launch_ii-agent.bat"
if errorlevel 1 (
    echo [ERROR] Не вдалося створити файл запуску!
    pause
    exit /b 1
)
echo [SUCCESS] Файл запуску launch_ii-agent.bat створено в %PROJECT_DIR%.
echo.

:: === 10. Завершення ===
echo [SUCCESS] Встановлення та налаштування II-Agent завершено!
echo.
if defined LLM_SETUP_INSTRUCTIONS (
    echo [IMPORTANT] %LLM_SETUP_INSTRUCTIONS%
    echo.
)
echo Щоб запустити агент:
echo 1. Перейдіть до папки: cd "%PROJECT_DIR%"
echo 2. Запустіть: launch_ii-agent.bat
echo.
echo Гарного дня!
pause
exit /b 0