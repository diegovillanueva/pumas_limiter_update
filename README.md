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

## Usage

```bash
git clone -b release-cesm2.1.5 https://github.com/ESCOMP/CESM.git cesm215
cd cesm215 && ./manage_externals/checkout_externals && cd ..
git clone https://github.com/ESCOMP/PUMAS.git
git -C PUMAS checkout e7377aeeff15acf28c8edf42e9c50b6e89f7de11
git clone -b v1.0.0 https://github.com/diegovillanueva/PUMAS_interface_215.git
git clone https://github.com/diegovillanueva/pumas_limiter_update.git

PUMAS_interface_215/scripts/apply_interface.sh PUMAS cesm215/components/cam
cesm215/cime/scripts/create_newcase --case my_case --compset F2000climo --res f09_f09_mg17 --run-unsupported
pumas_limiter_update/scripts/apply_pumas_patches.sh PUMAS cesm215/components/cam my_case
cp pumas_limiter_update/namelists/user_nl_cam.DustOnly-NieSing-PUMAS my_case/user_nl_cam
cd my_case && ./case.setup && ./case.build && ./case.submit
```

The namelist uses nudging; set `Nudge_Path` to the directory of the nudging
files before submitting, or remove the `Nudge_*` entries for a free run.

## Validation

All patches apply with `git apply --check` to the pinned commits in the order
above. The resulting CAM tree and the ten PUMAS files are identical to the
source compiled for the simulations (comments aside: decorative symbols were
removed from comment lines).

## Related repositories

- [mg2_limiter_update](https://github.com/diegovillanueva/mg2_limiter_update): the limiter for MG2 microphysics (CESM 2.1.5 default).
- [PUMAS_interface_215](https://github.com/diegovillanueva/PUMAS_interface_215): CAM patches that let CESM 2.1.5 run PUMAS.
- [pumas_limiter_update](https://github.com/diegovillanueva/pumas_limiter_update): the limiter for PUMAS, applied on top of PUMAS_interface_215.
