# local_smart_linux_assistant
# 🧠 Smart Linux Co-Pilot — AI-Powered Terminal Assistant

> A local, privacy-focused assistant for Linux users — powered by a fine-tuned Phi-2 model running offline via Ollama.

---

## 📌 Overview

**Smart Linux Co-Pilot** is a personal project aiming to bring a smart, offline AI assistant to the Linux terminal. It's designed to help users — especially beginners — understand and use Linux commands through natural language conversations.

The assistant runs entirely offline using a **fine-tuned Phi-2 model**, making it fast, lightweight, and private.

---

## ✅ Current Capabilities

- 💬 Interact with the assistant through a **text-based CLI interface**
- 🧠 Uses a **locally fine-tuned Phi-2 model** for understanding queries
- 📂 Responds to system-related questions like:
  - “List files in the current directory”
  - “How do I check system memory?”
  - “What does the 'grep' command do?”
- ⚙️ Suggests safe Linux commands based on natural language inputs
- 🔒 Works completely offline — no API calls, no cloud

---

## 🏗️ Work in Progress

- [ ] Expand understanding of Linux commands and system operations
- [ ] Add command execution (currently suggests only)
- [ ] Add simple help/documentation lookup from `man` pages
- [ ] Optional: integrate voice input in the future (Vosk/Whisper)
- [ ] Improve prompt engineering and fine-tuning dataset

---

## 🧠 Motivation

Many users avoid Linux because of its learning curve and cryptic commands. This project aims to:
- Make Linux **more user-friendly**
- Allow users to **learn Linux naturally** via conversation
- Build an AI assistant that runs **entirely on-device**, respecting user privacy

---

## 🧰 Tech Stack

| Component       | Tool / Library     |
|----------------|--------------------|
| Language Model | Fine-tuned Phi-2   |
| Runtime        | [`Ollama`](https://ollama.com/) |
| Backend        | Python              |
| Interface      | CLI (Terminal)      |
| OS Support     | Linux               |

---


## 🧪 Example Interaction

"""bash
> What command shows disk usage?

Assistant:
You can use: `df -h`  
It shows disk space in human-readable format.

> How to see hidden files?

Assistant:
Use: `ls -a` """

---

## Disclaimer

This project is in early development.

Voice input is not yet implemented.

Output is suggestive; command execution is not enabled yet.

---

## Contact

GitHub: 07Codex07

LinkedIn: www.linkedin.com/in/vinayak-sahu-8999a9259

Email: vinayak1672006@gmail.com


---

Let me know if you want:
- Help updating your `run_assistant.py` file structure
- A matching GitHub description and project tags
- LinkedIn or blog post format for this project

You're building this the right way — one real feature at a time.
