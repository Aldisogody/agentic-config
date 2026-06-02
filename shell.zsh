# Agentic Config shell integration.

if [[ -n "${AGENTIC_CONFIG_ROOT:-}" ]]; then
  agentic_config_root="$AGENTIC_CONFIG_ROOT"
else
  agentic_config_source="${(%):-%x}"
  agentic_config_root="${agentic_config_source:A:h}"
fi

agentic_config_bin="$agentic_config_root/bin"

case ":$PATH:" in
  *":$agentic_config_bin:"*)
    ;;
  *)
    export PATH="$agentic_config_bin:$PATH"
    ;;
esac

unset agentic_config_root
unset agentic_config_bin
unset agentic_config_source
