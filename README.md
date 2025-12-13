# HAMQTT.Net

**HAMQTT.Net** is a streamlined development framework designed to rapidly scaffold, build, and deploy **.NET-based MQTT integrations** for Home Assistant.

It abstracts away the complexity of managing Docker infrastructure, MQTT connectivity, and project scaffolding, allowing you to focus on the logic of your IoT integrations.

## 🚀 Features

* **⚡ Rapid Scaffolding:** Generate new .NET integration projects in seconds using custom templates.
* **🐳 Docker-First Workflow:** Automatically manages `docker-compose` configurations for development and production.
* **🛠️ CLI Tooling:** Includes a powerful cross-platform CLI (`hamqtt`) installed globally to manage the entire lifecycle.
* **🏠 Local Dev Environment:** One-command setup for a local Home Assistant and Mosquitto instance.
* **🔄 Auto-Discovery Ready:** Built on top of `HAMQTT.Integration` to easily interface with Home Assistant's MQTT discovery protocol.

---

## 📋 Prerequisites

Before using HAMQTT.Net, ensure you have the following installed:

1.  **.NET SDK 10.0** (or compatible version) - [Download](https://dotnet.microsoft.com/download)
2.  **Docker Desktop** (or Docker Engine + Docker Compose)
3.  **Git**
4.  *(Optional)* **PowerShell Core (pwsh)** - The underlying scripts run on PowerShell, but the CLI wrapper handles execution.

---

## 🛠️ Installation & Setup

HAMQTTN.et is distributed as a **.NET Global Tool**.

### 1. Install the CLI Tool
Open your terminal and run the following command to install the `hamqtt` tool globally on your system:

```bash
dotnet tool install -g HAMQTT.CLI
````

*Note: You may need to add the .NET tools directory to your PATH if you haven't done so already.*

### 2\. Initialize a Project

Create a new directory for your project and initialize the workspace. This sets up your solution file, secrets, and installs the necessary templates.

```bash
mkdir MyHomeAutomation
cd MyHomeAutomation
hamqtt init
```

> **Note on Credentials:** During initialization, you will be asked for your GitHub Username and a **Personal Access Token (PAT)**. This is required to restore the project templates and base libraries from the GitHub Package Registry.

-----

## 💻 Usage Guide

Once installed, the `hamqtt` command is available globally.

### Managing Integrations

**Create a new integration:**
Scaffolds a new .NET project and registers it in the development `docker-compose` file.

```bash
hamqtt integrations new MyDeviceName
```

*(Tip: Use PascalCase for names, e.g., `SolarEdge`, `SmartMeter`)*

**List integrations:**
View the status of all local integrations.

```bash
hamqtt integrations list
```

**Remove an integration:**
Deletes the project folder and removes it from the configuration.

```bash
hamqtt integrations remove
```

### Running the Environment

**Start Full Development Environment:**
Starts Mosquitto, Home Assistant, and **all** your created integrations in Docker containers.

```bash
hamqtt run dev
```

**Start Infrastructure Only (Bare Mode):**
Starts only Mosquitto and Home Assistant. Use this if you want to run/debug your .NET integration from your IDE (Visual Studio / Rider) while keeping the infrastructure containerized.

```bash
hamqtt run dev --bare
```

### Deployment

**Build for Production:**
Generates a production-ready `docker-compose.yml` file in the root directory (or specified output).

```bash
hamqtt integrations deploy
```

### Maintenance

**Update Tooling:**
To update the HAMQTT CLI to the latest version:

```bash
dotnet tool update -g HAMQTT.CLI
```

**Update Templates:**
To update the underlying project templates:

```bash
hamqtt template update
```

-----

## 📂 Project Structure

```text
/
├── docker-compose.yml          # (Generated) Production deployment file
├── .env                        # Secrets (GitIgnored)
├── docker-compose.dev.yml      # Local development infrastructure
├── ha_config/                  # Local Home Assistant configuration
└── HAMQTT.Integration.MyDevice # (Your custom integrations...)
```

-----

## 🔒 Configuration & Secrets

Configuration is managed via the **`.env`** file.

  * **MQTT\_HOST**: Hostname of the broker (default: `mosquitto` for Docker, `localhost` for IDE).
  * **MQTT\_USERNAME**: Broker username.
  * **MQTT\_PASSWORD**: Broker password.
  * **GITHUB\_USERNAME / GITHUB\_PAT**: Credentials for restoring NuGet packages.

> ⚠️ **Security Warning:** The `.env` file contains sensitive credentials. It should be added to `.gitignore`. Do not commit this file to version control.

-----

## 🤝 Contributing

1.  Fork the repository.
2.  Create a feature branch.
3.  Submit a Pull Request.

## 📄 License

[GNU Affero General Public License v3.0](LICENSE)

## 🔗 Repository

[https://github.com/mavanmanen/HAMQTT.Net](https://www.google.com/search?q=https://github.com/mavanmanen/HAMQTT.Net)
