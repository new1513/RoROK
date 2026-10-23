-- Central market tuning values. Pure data: the server owns every rule, the client
-- only reads these numbers to label the UI. All numbers are first-pass guesses
-- meant to be playtested; each one has a comment explaining why it exists.
return {
	-- ===== Auction =====
	-- Unique items sit in an auction for 30 minutes (the example in the design brief).
	AuctionDurationSeconds = 30 * 60,
	-- A new bid must beat the current bid by at least 5% (min 1 z) so bidders
	-- cannot crawl upward one Zeny at a time.
	AuctionMinRaiseFraction = 0.05,
	-- Only these item types are auctioned when no comparable listing exists.
	-- Materials/consumables/cards are commodities and always use fixed prices.
	AuctionItemTypes = { Equipment = true },

	-- ===== Money sinks and limits =====
	-- Sale tax is a Zeny sink so the market does not only inject currency.
	-- Set to 0 to disable. Paid by the seller from the proceeds.
	SaleTaxRate = 0.03,
	-- Caps stop one player filling the board and keep each snapshot small.
	MaxActiveListingsPerPlayer = 12,
	MaxQuantityPerListing = 9999,
	MaxPriceAllowed = 1000000000,
	MinUnitPrice = 2,
	InteractDistance = 14,

	-- ===== Price band (what the system allows a seller to ask) =====
	-- center = base * variantFactor * (1 + PressureSwing * pressure)
	-- pressure = (recentSold - listed) / (recentSold + listed + PressureSmoothing)  -> -1 .. +1
	-- Plenty listed and little sold pushes the band down (slime goo is cheap);
	-- heavy sales and little stock pushes it up.
	PressureSwing = 0.40,
	-- Smoothing keeps one lonely sale or listing from swinging the price wildly.
	PressureSmoothing = 10,
	-- Only sales in this window count as demand, so the band recovers over time.
	DemandWindowSeconds = 30 * 60,
	-- Sellers may price within +/-10% of the center (the brief's 10000..13000 style range).
	BandHalfWidth = 0.10,
	-- Hard limits relative to base value, so the price can never collapse to 0/1 z
	-- or run away no matter how much supply or demand there is.
	FloorMultiplier = 0.5,
	CeilingMultiplier = 2.0,

	-- ===== Base value =====
	-- Materials/consumables/cards: NPC sell price * this markup (market > NPC buyback).
	MaterialMarkup = 3,
	-- Equipment: sum(stat bonus * weight) * EquipmentPointValue.
	EquipmentPointValue = 40,
	EquipmentStatWeights = { ATK = 1, MATK = 1, DEF = 1, MDEF = 1, MaxHP = 0.2, MaxSP = 0.2 },
	-- Refinement raises value: factor = 1 + Linear*level + Quadratic*level^2.
	-- Convex because each extra level needs more expected attempts (100%..8% success).
	RefineLinear = 0.15,
	RefineQuadratic = 0.01,
	-- Explicit overrides for items whose rarity is not visible in sellPrice.
	-- Cards drop at 0.03-0.05%, so they are priced far above their NPC value.
	BasePrices = {
		PoringCard = 15000,
		LunaticCard = 25000,
	},

	-- ===== Not tradable =====
	-- The free starter kit and starter refine stones are untradable so new or alt
	-- accounts cannot print Zeny. Remove a line to allow trading that item.
	Untradable = {
		NoviceTrainingDagger = true,
		ApprenticeRod = true,
		AcolyteTrainingMace = true,
		KnightTrainingSword = true,
		ArcherTrainingBow = true,
		ThiefTrainingDagger = true,
		MerchantTrainingAxe = true,
		NoviceClothes = true,
		BeginnerRefinementStone = true,
	},
}
