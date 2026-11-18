#!/usr/bin/env bash
# Apply the PUMAS variant of the droplet freezing limiter.
# Prerequisite: CAM patched with PUMAS_interface_215 (scripts/apply_interface.sh there).
# Usage: scripts/apply_pumas_patches.sh <PUMAS_DIR> <CESM_ROOT>/components/cam [<CASE_DIR>]
#   PUMAS_DIR  clone of ESCOMP/PUMAS checked out at PUMAS_COMMIT (versions.env)
#   CAM dir    CAM checkout at cam_cesm2_1_rel_60 with PUMAS_interface_215 applied
#   CASE_DIR   optional: copy the ten PUMAS source files into <CASE_DIR>/SourceMods/src.cam
set -euo pipefail

usage="usage: apply_pumas_patches.sh <PUMAS_DIR> <CAM_DIR> [<CASE_DIR>]"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pumas="${1:?${usage}}"
cam="${2:?${usage}}"
case_dir="${3:-}"
# shellcheck source=/dev/null
source "${here}/versions.env"

check_head() {
    local dir="$1" want="$2" name="$3" head
    head="$(git -C "${dir}" rev-parse HEAD 2>/dev/null)" || { echo "ERROR: ${dir} is not a git checkout" >&2; exit 1; }
    if [[ "${head}" != "${want}" ]]; then
        echo "ERROR: ${name} HEAD ${head} is not ${want}" >&2
        exit 1
    fi
}
check_head "${pumas}" "${PUMAS_COMMIT}" "PUMAS"
check_head "${cam}" "${CAM_COMMIT}" "CAM"

if ! grep -q micro_pumas_nl "${cam}/src/physics/cam/micro_mg_cam.F90"; then
    echo "ERROR: ${cam} lacks the PUMAS interface; apply PUMAS_interface_215 first" >&2
    exit 1
fi
# Each tree is checked on its own: if the patch set reverses cleanly, it is already applied.
pumas_done=false
cam_done=false
git -C "${pumas}" apply --reverse --check "${here}"/patches/pumas/*.patch 2>/dev/null && pumas_done=true
git -C "${cam}" apply --reverse --check "${here}"/patches/cam/*.patch 2>/dev/null && cam_done=true
[[ "${pumas_done}" == true ]] || git -C "${pumas}" apply --check "${here}"/patches/pumas/*.patch
[[ "${cam_done}" == true ]] || git -C "${cam}" apply --check "${here}"/patches/cam/*.patch
if [[ "${pumas_done}" == true ]]; then
    echo "PUMAS already patched: ${pumas}"
else
    git -C "${pumas}" apply --whitespace=nowarn "${here}"/patches/pumas/*.patch
    echo "Patched PUMAS: ${pumas}"
fi
if [[ "${cam_done}" == true ]]; then
    echo "CAM already patched:   ${cam}"
else
    git -C "${cam}" apply --whitespace=nowarn "${here}"/patches/cam/*.patch
    echo "Patched CAM:   ${cam}"
fi

if [[ -n "${case_dir}" ]]; then
    dest="${case_dir}/SourceMods/src.cam"
    [[ -d "${dest}" ]] || { echo "ERROR: ${dest} not found" >&2; exit 1; }
    for f in pumas_kinds pumas_gamma_function micro_pumas_sppe micro_pumas_utils micro_pumas_diags \
             pumas_stochastic_collect_tau module_neural_net tau_neural_net_quantile ML_fixer_check micro_pumas_v1; do
        cp "${pumas}/${f}.F90" "${dest}/"
        echo "${dest}/${f}.F90"
    done
fi
