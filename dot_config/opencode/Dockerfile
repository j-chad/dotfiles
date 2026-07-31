FROM docker/sandbox-templates:opencode-docker
USER agent
COPY --chown=agent:agent opencode.sbx.json /home/agent/.config/opencode/opencode.json
COPY --chown=agent:agent skills /home/agent/.config/opencode/skills
COPY --chown=agent:agent agents /home/agent/.config/opencode/agents