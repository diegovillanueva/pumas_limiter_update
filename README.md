# pumas_limiter_update

Droplet freezing limiter of [mg2_limiter_update](https://github.com/diegovillanueva/mg2_limiter_update), ported to the
PUMAS cloud microphysics (`micro_mg_version = 3`) in CESM 2.1.5. It is the
model configuration of the `DustOnly-NieSing-PUMAS` simulations.

## Layers

1. CESM 2.1.5, CAM `cam_cesm2_1_rel_60`, PUMAS (ESCOMP/PUMAS `main_cam`,
   commit `e7377aeeff15acf28c8edf42e9c50b6e89f7de11`), all unmodified.
2. [PUMAS_interface_215](https://github.com/diegovillanueva/PUMAS_interface_215)
   v1.0.0: lets CAM call PUMAS (`micro_mg_cam`, `wv_sat_methods`,
   `check_energy`, namelist group `micro_pumas_nl`).
3. This repository:
   - `patches/pumas/`: the limiter in `micro_pumas_v1.F90` and
     `micro_pumas_utils.F90`, and the new module `micro_pumas_sppe.F90`
     (process switches whose defaults reproduce upstream PUMAS).
   - `patches/cam/`: the same CAM changes as the MG2 variant in
     mg2_limiter_update (`hetfrz_classnuc`, `hetfrz_classnuc_cam`, `nucleate_ice`,
     `microp_aero`, `ndrop`, `clubb_intr`, `macrop_driver`, the namelist
     module `micro_dv_nml.F90` and its group `micro_dv_nl`), plus the PUMAS
     wiring of these switches in `micro_mg_cam.F90`. The CAM patches apply
     to the state after layer 2.
   - `namelists/user_nl_cam.DustOnly-NieSing-PUMAS`: namelist of the runs.
   - `scripts/apply_pumas_patches.sh`: checks the pins, applies both patch
     sets and copies the ten PUMAS source files into a case.
   - `versions.env`: commit pins.
   - `LICENSE`, `NOTICE`: BSD 3-Clause License; terms of the modified CESM2 code and of PUMAS.
   - `CITATION.cff`, `.zenodo.json`: citation and archive metadata.
   - `SHA256SUMS`: checksums of all tracked files (`sha256sum -c SHA256SUMS`).

## Usage

```bash
git clone -b release-cesm2.1.5 https://github.com/ESCOMP/CESM.git cesm215
cd cesm215 && ./manage_externals/checkout_externals && cd ..
git clone https://github.com/ESCOMP/PUMAS.git
git -C PUMAS checkout e7377aeeff15acf28c8edf42e9c50b6e89f7de11
git clone -b v1.0.0 https://github.com/diegovillanueva/PUMAS_interface_215.git
git clone -b v1.0.1 https://github.com/diegovillanueva/pumas_limiter_update.git

PUMAS_interface_215/scripts/apply_interface.sh PUMAS cesm215/components/cam
cesm215/cime/scripts/create_newcase --case my_case --compset F2000climo --res f09_g17 --run-unsupported
pumas_limiter_update/scripts/apply_pumas_patches.sh PUMAS cesm215/components/cam my_case
cp pumas_limiter_update/namelists/user_nl_cam.DustOnly-NieSing-PUMAS my_case/user_nl_cam
cd my_case && ./xmlchange --append CAM_CONFIG_OPTS=-cosp
./case.setup && ./case.build && ./case.submit
```

The namelist uses nudging; set `Nudge_Path` to the directory of the nudging
files before submitting, or remove the `Nudge_*` entries for a free run.
The simulations used the grid `f09_g17`, as in mg2_limiter_update. The
namelist requests COSP fields, hence the `-cosp` build option.

The namelist sets `limfacdu = 0.051`, the value used in the original MG2
runs and in these PUMAS simulations. mg2_limiter_update uses `0.05`, the
value quoted in Villanueva et al. (in review); see its section
"Differences from the original runs".

## CALIPSO cloud-top phase fields

Stock CAM 6 COSP (`cam_cesm2_1_rel_60`) writes `CLD_CAL_TMPLIQ` and
`CLD_CAL_TMPICE` swapped: in COSP2 `lidarcldtmp` index 2 is ice and index 3
is liquid, but stock CAM maps them the other way. This repository does not
modify COSP, so runs built from it get swapped fields (the
DustOnly-NieSing-PUMAS simulations included). Apply the fix from
[cam6_cosp_calipso_diag](https://github.com/diegovillanueva/cam6_cosp_calipso_diag)
or swap the two fields in post-processing.

## Validation

All patches apply with `git apply --check` to the pinned commits in the order
above. The resulting CAM tree and the ten PUMAS files are identical to the
source compiled for the simulations (comments aside: decorative symbols were
removed from comment lines).

## Citation

Please cite this software via the Zenodo DOI of the release; the citation
metadata are in `CITATION.cff`.

## Versions and releases

Release v1.0.2 of mg2_limiter_update and release v1.0.1 of PUMAS_interface_215 change only documentation and metadata; their code is identical to mg2_limiter_update v1.0.1 and PUMAS_interface_215 v1.0.0. Pins to those two code versions in this repository (`versions.env`, Usage) therefore remain valid.

## Related repositories

- [mg2_limiter_update](https://github.com/diegovillanueva/mg2_limiter_update): droplet freezing limiter and microphysics switches for MG2 (CESM 2.1.5 default), with the run configurations.
- [cam6_cosp_calipso_diag](https://github.com/diegovillanueva/cam6_cosp_calipso_diag): COSP, CALIPSO/CloudSat and cloud-top diagnostics, including the fix of the swapped `CLD_CAL_TMPLIQ`/`CLD_CAL_TMPICE` fields.
- [PUMAS_interface_215](https://github.com/diegovillanueva/PUMAS_interface_215): CAM patches that let CESM 2.1.5 run PUMAS.
