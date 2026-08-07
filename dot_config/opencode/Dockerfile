FROM docker/sandbox-templates:opencode-docker
USER agent
# A bug in sbx is overwriting the config file
COPY --chown=agent:agent opencode.sbx.json /home/agent/.opencode.json
COPY --chown=agent:agent skills /home/agent/.config/opencode/skills
COPY --chown=agent:agent agents /home/agent/.config/opencode/agents
COPY --chown=agent:agent tui.json /home/agent/.config/opencode/tui.json
ENV OPENCODE_CONFIG=/home/agent/.opencode.json