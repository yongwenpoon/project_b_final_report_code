# Project B Final Report Code

This repository contains the MATLAB code used to generate the analyses, figures, and tables for the final report of **Project B**, which studies post-crisis brand-trust dynamics using a belief-system dynamics model.

## Project focus

The report examines whether a direct negative shock to perceived quality can generate broader decline in brand trust without a direct trust shock, and how the severity of that decline changes under different conditions.

The final report uses three focal topics:

- **BT** = Brand Trust
- **Q** = Perceived Quality
- **OM** = Official Message credibility

## Repository purpose

This repository is organised for **report reproduction**, not for development history.

It contains:

- the final report-facing runner scripts for Sections 4.1–4.6
- the core MATLAB functions required to run those analyses
- the exported figures and tables corresponding to the report results


## Main report runners

Run the following scripts to reproduce the main report results.

### 1. Sections 4.1–4.3
`run_report_section_4_1_to_4_3.m`

Generates:

- Figure 4.1: `Figure_4_1_S0_Baseline_AllAgents.png`
- Figure 4.2: `Figure_4_2_S1_MainShock_AllAgents.png`
- Figure 4.3: `Figure_4_3_BT_ByRole_S0_vs_S1.png`
- Appendix Figure A1: `Appendix_A1_RoleSpecific_AllTopics.png`
- Table 4.2: `Table_4_2_S0_vs_S1_AllAgentSummary.csv`
- Table 4.3: `Table_4_3_BT_ByRole_MainShock.csv`

Outputs are saved in:

`report_outputs_4_1_to_4_3/`

---

### 2. Section 4.4 Shock reach
`run_report_section_4_4_shock_reach.m`

Generates:

- Figure 4.4: `Figure_4_4_ShockReach_BT_Only.png`
- Appendix Figure A2: `Appendix_A2_ShockReach_BTQ_VaryingExposure.png`
- Table 4.4: `Table_4_4_ShockReach_BT_Summary.csv`
- Appendix Table A2: `Appendix_Table_A2_ShockReach_FullSummary.csv`

Outputs are saved in:

`report_outputs_4_4_shock_reach/`

---

### 3. Section 4.5 Topic-logic comparisons
`run_report_section_4_5_topic_logic.m`

Generates:

- Figure 4.5: `Figure_4_5_TopicLogic_Ordinary_BT.png`
- Table 4.5: `Table_4_5_TopicLogic_Ordinary_BT.csv`

Outputs are saved in:

`report_outputs_4_5_topic_logic/`

---

### 4. Section 4.6 Shock-channel comparison
`run_report_section_4_6_shock_channel.m`

Generates:

- Figure 4.6: `Figure_4_6_ShockChannel_BT_Only.png`
- Appendix Figure A3: `Appendix_A3_ShockChannel_Topics_Q_OM.png`
- Appendix Figure A4: `Appendix_A4_ShockChannel_FinalBT_ByRole.png`
- Table 4.6: `Table_4_6_ShockChannel_BT_Summary.csv`
- Appendix Table A3: `Appendix_Table_A3_ShockChannel_RoleBT.csv`

Outputs are saved in:

`report_outputs_4_6_shock_channel/`

---

## Core supporting files

The report runners depend on the following core MATLAB files:

- `run_S0_S1_dynamics_projectB_single.m`
- `plot_report_section_4_1_to_4_3.m`
- `get_cfg_projectB.m`
- `generate_network_projectB.m`
- `build_W_lambda_projectB.m`
- `generate_X0_projectB.m`
- `build_C_projectB.m`
- `run_dynamics_projectB.m`
- `apply_S1_quality_shock_projectB.m`
- `apply_S1_quality_shock_projectB_partial.m`

## Default configuration

The final report configuration is defined in:

`get_cfg_projectB.m`

The default preset is:

`main`

This corresponds to the report’s main population setting:

- 1000 agents total
- 990 ordinary consumers
- 2 official agents
- 8 eWOM influencers

## Software

This code was written and tested in MATLAB R2025b (64-bit, macOS).
No special toolbox is intentionally required beyond standard MATLAB functionality used in the scripts.

## Notes on reproduction

- The scripts are organised to reproduce the **final report figures and tables**, not all intermediate exploratory analyses.
- The report-facing runners save outputs into section-specific folders.
- If running in a fresh folder, keep all required `.m` files in the same repository root unless you explicitly reorganise the MATLAB path.

## Report link

This repository accompanies the final report for Project B.

The MATLAB code used to generate the analyses, figures, and tables in the report is provided here for auditing and reproduction.