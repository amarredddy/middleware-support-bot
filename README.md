# Middleware Support Chatbot - Phase 1

A standalone FastAPI + HTML/CSS/JS chatbot for the five middleware products
(WebSphere, Apache, Tomcat, JBoss, Liberty): product resources, guided
support, incident routing, and an Application Runtime escalation flow that
ends with a GitHub issue URL. **No external integrations are wired up yet**
- GitHub, ServiceNow, and xMatters are just links the chatbot hands the user;
nothing is called via API. That's intentional for phase 1.

```
middleware-support-bot/
├── app/
│   ├── main.py        FastAPI app + all /api/* routes
│   ├── config.py       loads config/support.yaml (or CONFIG_PATH)
│   └── models.py       request/response schemas
├── static/
│   ├── index.html
│   ├── styles.css
│   └── app.js           chat state machine
├── config/support.yaml  product resources, GitHub repos, ServiceNow/xMatters links
├── Dockerfile
├── deploy.yaml           Namespace, ConfigMap, BuildConfig, Deployment, Service, Route, HPA
└── requirements.txt
```

## 1. Run it locally

```bash
cd middleware-support-bot
python3 -m venv .venv
source .venv/bin/activate            # Windows: .venv\Scripts\activate
pip install -r requirements.txt

uvicorn app.main:app --reload --port 8080
```

Open **http://localhost:8080**. Edit `config/support.yaml`, then call
`POST /api/config/reload` (or just restart uvicorn) to pick up changes.

## 2. Put your real links in before deploying

Every URL in `config/support.yaml` (and the copy embedded in `deploy.yaml`'s
ConfigMap) is a placeholder. As the admin, replace:

| Placeholder | Replace with |
|---|---|
| `YOUR_WEBSPHERE_ADMIN_CONSOLE.example.com` | Your real WebSphere admin console URL |
| `YOUR_PCC_CATALOG.example.com` | Your product catalog / PCC URL |
| `wiki.YOUR_ORG.example.com/...` | Your internal wiki/runbook links |
| `YOUR_MONITORING_TOOL.example.com` | Your monitoring dashboards (Grafana, Dynatrace, etc.) |
| `YOUR_INSTANCE.service-now.com` | Your ServiceNow instance |
| `YOUR_ORG.xmatters.com` | Your xMatters trigger URL |
| `middleware-ops@YOUR_ORG.example.com` | Your Middleware Operations DL |
| `YOUR_GITHUB_ORG` | The GitHub org that owns your five support repos |

## 3. Create the GitHub repos (admin, one-time)

Phase 1 only *links* to GitHub Issues - it doesn't call the GitHub API - so
all you need is one issues-enabled repo per product, under whatever GitHub
org/account you administer:

- `https://github.com/YOUR_GITHUB_ORG/websphere-support`
- `https://github.com/YOUR_GITHUB_ORG/apache-support`
- `https://github.com/YOUR_GITHUB_ORG/tomcat-support`
- `https://github.com/YOUR_GITHUB_ORG/jboss-support`
- `https://github.com/YOUR_GITHUB_ORG/liberty-support`

For **this bot's own source code**, push it to a repo you control, e.g.:

```bash
cd middleware-support-bot
git init
git add .
git commit -m "Middleware support chatbot - phase 1"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_ORG/middleware-support-bot.git
git push -u origin main
```

(If you want a public reference implementation to compare patterns against
later - for phase 2/3 GitHub and Slack integration - the official SDKs are
`PyGithub/PyGithub` and `slackapi/bolt-python` on GitHub. Nothing from them
is used in this phase.)

## 4. Deploy to OpenShift

Requires the `oc` CLI logged in to your cluster and permission to create a
namespace (or ask an admin to create `middleware-support` for you and grant
you edit access).

```bash
# 1. Log in
oc login https://api.YOUR_CLUSTER:6443

# 2. Edit deploy.yaml: set your namespace name (if different) and the
#    ConfigMap's support.yaml block with your real links from step 2.

# 3. Create everything: namespace, ConfigMap, ImageStream, BuildConfig,
#    Deployment, Service, Route, autoscaler
oc apply -f deploy.yaml

# 4. Upload your source and build the image (binary build - no external
#    git/webhook needed for phase 1)
oc -n middleware-support start-build middleware-support-bot --from-dir=. --follow

# 5. Watch the rollout
oc -n middleware-support rollout status deployment/middleware-support-bot

# 6. Get the URL
oc -n middleware-support get route middleware-support-bot -o jsonpath='{.spec.host}{"\n"}'
```

Open the printed hostname in a browser - that's the chatbot.

### Updating links later (no rebuild needed)

```bash
oc -n middleware-support edit configmap middleware-support-content
# edit the support.yaml content, save/exit
oc -n middleware-support rollout restart deployment/middleware-support-bot
```

### Updating code later (rebuild)

```bash
oc -n middleware-support start-build middleware-support-bot --from-dir=. --follow
```

## 5. Embedding as a Teams tab (still phase 1, no bot-framework integration)

The running chatbot is a normal web page, so once you have the OpenShift
Route URL you can add it as a **Teams tab** (Teams admin center or app
manifest, static tab pointing at your Route URL, HTTPS required - the Route
already terminates TLS). This is not a conversational Teams bot yet; it's
the same GUI opened inside a Teams tab.

## Roadmap

- **Phase 1 (this):** standalone chatbot, five product resource sets,
  guided support, incident routing, escalation report generator, GitHub
  issue URL validation. No API calls to GitHub/ServiceNow/xMatters.
- **Phase 2:** real GitHub integration - create the issue via the GitHub API
  instead of asking the user to paste the report and URL back.
- **Phase 3:** Slack integration alongside Teams.
