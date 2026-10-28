# TierBanner

The centre-screen banner when the ball reaches a new tier: the tier number in its `tier-n` chip and the tier headline in `banner` caps. It holds for `Config.tierBannerDuration` (2.5 s) while the camera pulls back.

- **Consumer provides**: the tier number and its headline key (`tier.<world>.<n>.headline`), localised.
- **Use it** once per tier per run; it is the moment players clip, so nothing else pops at the same time.
- **Do** name the most exciting thing the player can now eat ("BUSES", not "VEHICLES").
- **Don't** add offers or shop links to it (Constitution V: no pop-up offers during a run).
