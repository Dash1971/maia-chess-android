# In-app explanation

**Why Temperature 1.00 and Top-P 1.00?**

These settings let Maia use its full range of predicted human moves. In our tests at the 1600 setting, they produced opening choices much closer to rating-filtered Lichess games. Lower settings reduce variety and can make Maia stronger. We favor a more human opening repertoire over maximum strength. Maia's rating describes the players it models, rather than guaranteeing an exact playing strength.

[Read the sampling research](REPORT.md)

The app also explains how each control works. Existing valid saved values remain unchanged; an inline reminder appears when either value differs from 1.00. Reset restores both to 1.00.
