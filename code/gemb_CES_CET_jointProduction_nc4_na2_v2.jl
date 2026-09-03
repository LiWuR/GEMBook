# ================================================================
# gemb_CES_CET_jointProduction_nc4_na2_v1.jl
#
# CES-CET joint-production equilibrium:
# one producer and one consumer who consumes all four commodities.
#
# Commodities:
#   1. product1
#   2. product2
#   3. labor
#   4. land
# ================================================================

using GeneralEquilibriumModeling


# ----------------------------------------------------------------
# 1. Parameters
# ----------------------------------------------------------------

omega_labor = 100.0
omega_land = 100.0

# Production:
#
#   z = x_labor^(2/3) * x_land^(1/3)
#
input_spec = GEMB.CESSpec(
    [2 / 3, 1 / 3];
    es=1.0,
    alpha=1.0,
)

# CET transformation:
#
#   y1^2 + 2*y2^2 = 3*z^2
#
output_spec = GEMB.CETSpec(
    [2 / 3, 1 / 3];
    et=1.0,
    alpha=sqrt(2) / 3,
)

# Consumer utility:
#
#   u = c1^(1/6) * c2^(1/3) * c3^(1/3) * c4^(1/6)
#
utility_spec = GEMB.CESSpec(
    [1 / 6, 1 / 3, 1 / 3, 1 / 6];
    es=1.0,
    alpha=1.0,
)


# ----------------------------------------------------------------
# 2. High-level GEMB model
# ----------------------------------------------------------------

model = GEMB.GEMBModel(
    [:product1, :product2, :labor, :land];
    numeraire=:product1,
    numeraire_value=1.0,
)


# ----------------------------------------------------------------
# 3. Producer
# ----------------------------------------------------------------

GEMB.add_agent!(
    model,
    input_spec;
    outputs=[:product1, :product2],
    output_spec=output_spec,
    demands=[:labor, :land],
    activity_start=100.0,
    name=:firm,
)


# ----------------------------------------------------------------
# 4. Consumer
# ----------------------------------------------------------------

GEMB.add_agent!(
    model,
    utility_spec;
    demands=[:product1, :product2, :labor, :land],
    endowments=[:labor, :land],
    endowment_quantities=[omega_labor, omega_land],
    activity_start=100.0,
    name=:consumer,
)


# ----------------------------------------------------------------
# 5. Solve
# ----------------------------------------------------------------

result = GEMB.solve(
    model;
    p0=ones(4),
    residual_tol=1.0e-10,
    silent=true,
)


# ----------------------------------------------------------------
# 6. Results
# ----------------------------------------------------------------

prices = result.prices
firm_activity = result.agent_variable_values[1][1]
consumer_utility = result.agent_variable_values[2][1]

println("Solved:            ", result.solved)
println("Prices:            ", prices)
println("Firm activity:     ", firm_activity)
println("Consumer utility:  ", consumer_utility)
println("Firm net supply:   ", result.agent_net_supplies[1])
println("Consumer net supply:", result.agent_net_supplies[2])
println("Total net supply:  ", result.total_net_supply)

println()
GEMB.print_equilibrium_statistics(
    model,
    result;
    display_tol=1.0e-10,
    sigdigits=8,
)
