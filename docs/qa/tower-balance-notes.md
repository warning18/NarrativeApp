## What the batch says (v1.848, after #837)

**The totals sit inside Core's bands** (median 13 to 18, floor 20 at 25 to 35%, top 5 to 12% with no unlocks, 15 to 25% with all). Two ranges of 2,000 seeds, both ways (1 to 2000 and 10001 to 12000): median floor 17 and 17, floor 20 at 33.3% and 33.9%, top with no unlocks 9.7% and 10.8%, with all unlocks 19.9% and 17.1%. The guards of `test/qa_tower_sim_test.dart` hold the bands on seeds 1 to 500.

1. **The professions are evened out**: the top rate with no unlocks runs from 8.3% (mage) to 11.5% (warrior), against 0.5% to 15.2% in v1.845. The rogue still reaches floor 20 far more than the mage (45.2% against 26.3%; median floor 18 against 15). Cleric and ranger are not in the start set: with all unlocks they win 15.9% and 22.3%.
2. **The clan is now the widest split**: Dominion wins the top 15.0% with no unlocks (29.1% with all), Penitents 9.0% (20.8%), Mire 4.7% (14.0%; median floor 13, floor 20 at 21.8%). Compact, Crows and Vigil come with unlocks (17.9%, 20.3%, 16.5%).
3. **The bosses are harder but still not walls**: win rate of the runs that reach the floor, no unlocks: floor 5 warden 99.1%, 10 boss 93.2%, 15 warden 92.5%, 20 boss 89.0%, 25 warden 86.1%, 30 top boss 85.5%. With all unlocks floor 20 is won less (85.3%) than with none (89.0%); not explained.
4. The bot never refuses a card, so a run earns 26.5 marks on average (median 25; 32.0 with all unlocks).

**What the bot cannot say (Core's note).** It plays on the headless fight (`simulateSimFight`): that fight has **no affixes** (the real one has them, so the real floors are harder), and the clan die's resonance and the specialisations are not simulated. The splits above are findings to check, not verdicts.
