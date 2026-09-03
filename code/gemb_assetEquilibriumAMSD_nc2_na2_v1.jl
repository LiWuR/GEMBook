using GeneralEquilibriumModeling

Supply = [
    100.0  100.0
    100.0  100.0
]

PMP = [
    1.20  1.05
    1.05  1.20
]

PSD = [
    0.20  0.20
    0.30  0.30
]

Cor = [
    1.0  0.0
    0.0  1.0
]

gamma = [0.7, 1.0]

result = GEMB.solve_asset_equilibrium_amsd(
    Supply=Supply,
    gamma=gamma,
    PMP=PMP,
    PSD=PSD,
    Cor=Cor,
    x0=fill(100.0, 2, 2),
    silent=true,
)

println("Prices: ", result.p)
println("Holdings:")
display(result.D)