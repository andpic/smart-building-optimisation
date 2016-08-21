# Optimisation problem: single household
#
# The formulation of the model is taken from: 
#     Zhao, Chen, Shufeng Dong, Furong Li, and Yonghua Song. "Optimal home energy management system
#     with mixed types of loads." CSEE Journal of Power and Energy Systems 1, no. 4 (2015): 29-37.
# Data is either taken from online resources or randomly generated.
#
# Author: Andrea Picciau <a.picciau13@imperial.ac.uk>

# Problem scale parameters
param T := 0.25;          # Time step [h]
param H := 24*7;          # Horizon [h]


param N := floor(H/T);        # Number of time steps
param one_day := round(24/T); # Time steps in a day
param days := floor(H/24);    # How many days in horizon

set A := { 0 .. N-1 };        # Activity time of the plant

# System parameters
param eta_AD := 0.9;       # AC-to-DC conversion efficiency
param eta_DA := 0.7;       # DC-to-AC conversion efficiency
param SOC_min := 0.3;      # Minimum status of charge (SOC)
param SOC_max := 0.9;      # Maximum SOC 
param I_D_max := 20;       # Discharging current limit [Ah]
param I_C_max := 20;       # Charging current limit [Ah]
param eta_C := 0.9;        # Charge/discharge efficiency
param R := 4;              # Battery capacity [kWh]
param E_0 := 2;            # Initial energy in the battery [kWh]
param C[A] :=              # Cost [£/kWh]
   read "cost.dat" as "1n" comment "#";
param P_DC_load[A] :=      # DC load [kW]
   read "dc_load.dat" as "1n" comment "#";
param P_AC_load[A] :=      # AC load [kW]
   read "ac_load.dat" as "1n" comment "#";
param P_PV[A] :=           # PV output [kW]
   read "pv_output.dat" as "1n" comment "#";

# Secondary parameters
param E_min := SOC_min*R;                   # Minimum energy that can be stored in the battery
param E_max := SOC_max*R;                   # Maximum energy that can be stored in the battery
param P_D_max := -eta_C*I_D_max*230*1e-3;   # Maximum discharging rate [kW]
param P_C_max := eta_C*I_C_max*230*1e-3;    # Maximum charging rate [kW]

# Checking some parameters
do check E_0 >= E_min and E_0 <= E_max;
do check 24 mod T == 0;

# Variables
var P[A] real;                            # Power required from the main grid [kW]
var P_AC_DC[A] real >= -infinity;         # AC to DC power flow [kW]
var P_DC[A] real >= -infinity;            # Power flow on the DC bus [kW]
var P_B[A] real >= P_D_max <= P_C_max;    # Battery power flow [kW]
var E_B[A] real >= E_min <= E_max;        # Energy stored in the battery at time step t [kWh]
var E[A] real >= -infinity;               # Energy taken from/put into the battery at time step t [kWh]

# Auxiliary variables
var DC_bus[A] binary;                     # 1 when converting AC to DC, 0 when DC to AC

# Objective
minimize cost : 
   sum <t> in A : C[t]*P[t]*T;

# Power from the grid
subto total_power : 
   forall <t> in A :
      P[t] == P_AC_load[t]+P_AC_DC[t];

# AC power
subto DC_bus_bind_positive :
   forall <t> in A :
      DC_bus[t]*P_DC[t] >= 0;      
subto DC_bus_bind_negative :
   forall <t> in A :
      (DC_bus[t]-1)*P_DC[t] >= 0;      

subto AC_power :
   forall <t> in A :
      P_AC_DC[t] == (eta_AD*DC_bus[t]+eta_DA*(1-DC_bus[t]))*P_DC[t];

# DC power
subto DC_power : 
   forall <t> in A :
      P_DC[t]+P_PV[t] == P_DC_load[t]+P_B[t];

# Battery energy
subto battery_energy_total :
   forall <t> in A :
     E_B[t] == E_0+(sum <i> in { 0 .. t } : E[i]);

# # Battery energy/power equation
subto battery_energy_power :
   forall <t> in A :
      E[t] == P_B[t]*T;

# Battery cycle
subto battery_cycle :
   forall <t> in A with t<=days*one_day-1 :
      -0.0001 <= (sum <i> in A with i>=t and i<=t+one_day-1 : P_B[i]) <= 0.0001;
