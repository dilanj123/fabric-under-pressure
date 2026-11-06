#!/usr/bin/env bash
# Load the project's pinned OSS CAD Suite release for sourced run scripts.
# Set OSS_CAD_SUITE_ROOT when it is installed outside the qualified default.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "source this helper from a project run script" >&2
  exit 2
fi

OSS_CAD_SUITE_ROOT="${OSS_CAD_SUITE_ROOT:-${HOME}/eda/fabric-under-pressure/oss-cad-suite}"
if [[ ! -r "$OSS_CAD_SUITE_ROOT/environment" || ! -r "$OSS_CAD_SUITE_ROOT/VERSION" ]]; then
  echo "OSS CAD Suite not found at '$OSS_CAD_SUITE_ROOT'; set OSS_CAD_SUITE_ROOT to the qualified installation" >&2
  return 1
fi
OSS_CAD_SUITE_ROOT="$(cd "$OSS_CAD_SUITE_ROOT" && pwd -P)"
OSS_CAD_SUITE_LIB="$OSS_CAD_SUITE_ROOT/lib"
export OSS_CAD_SUITE_ROOT OSS_CAD_SUITE_LIB

suite_version="$(<"$OSS_CAD_SUITE_ROOT/VERSION")"
if [[ "$suite_version" != "20260920" ]]; then
  echo "OSS CAD Suite version mismatch: expected 20260920, found '$suite_version' at '$OSS_CAD_SUITE_ROOT'" >&2
  return 1
fi

# The suite's environment script puts its own executables first on PATH.
# Reject incomplete installations instead of silently falling back to tools
# elsewhere on the host.
source "$OSS_CAD_SUITE_ROOT/environment"
for tool in verilator yosys sby nextpnr-ecp5 ecppack yices-smt2 python3; do
  tool_path="$(command -v "$tool" || true)"
  case "$tool_path" in
    "$OSS_CAD_SUITE_ROOT"/*) ;;
    *)
      echo "qualified tool '$tool' did not resolve inside '$OSS_CAD_SUITE_ROOT' (got '${tool_path:-not found}')" >&2
      return 1
      ;;
  esac
done

require_version() {
  local tool="$1" expected="$2" actual
  shift 2
  actual="$("$@" 2>&1)"
  if [[ "$actual" != *"$expected"* ]]; then
    echo "qualified tool version mismatch for '$tool': expected '$expected', got '$actual'" >&2
    return 1
  fi
}
require_version verilator "5.053 devel rev v5.052-119-g014c9820d (mod)" verilator --version
require_version yosys "0.69+75" yosys --version
require_version sby "v0.69" sby --version
require_version nextpnr-ecp5 "0.11.1-30-g3e53a0bf" nextpnr-ecp5 --version
require_version ecppack "1.4-82-g3afe7b5" ecppack --version
require_version yices-smt2 "2.7.0" yices-smt2 --version
require_version python3 "3.11.6" python3 --version

if [[ -z "${LIBPYTHON_LOC:-}" ]]; then
  libpython="$(find "$OSS_CAD_SUITE_LIB" -maxdepth 1 -name 'libpython*.dylib' -print -quit 2>/dev/null || true)"
  [[ -z "$libpython" ]] || export LIBPYTHON_LOC="$libpython"
fi
export DYLD_LIBRARY_PATH="$OSS_CAD_SUITE_LIB${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
echo "Using qualified OSS CAD Suite release 20260920" >&2
