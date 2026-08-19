# Avatars by rating

Every opponent on the ladder, in roster order, with everything known about it:
what it is configured to do, what it measured when last calibrated, and the
prompt its portrait was generated from.

**Generated, not maintained by hand.** The configuration comes from
`packages/quadrim_engine/lib/src/bot.dart`, the measured ratings from a
`calibrate.dart` run, and the prompts from
[history/Avatars.md](history/Avatars.md) and
[history/avatars-new-opponents.md](history/avatars-new-opponents.md). If any of
those change, this file is stale — regenerate it rather than editing it.

**On the measured column.** A rating is an *anchor* and does not move: where
measurement disagrees, the configuration is what changes (D144). The figures
below are from a 140-pair run at 10% node budget, so **anything in the Master
tier is unreliable** — that reduction has been shown to reverse a result
outright, not merely blur it (D342).


---

## Novice — free from first launch

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>600 — Pebble</h3>
<p><i>Tiny stone creature.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>600</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>462 (-138)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>71%</td></tr></table>
<p><b>Prompt</b><br><sub>Cute pebble golem, round stone body, small moss patches, glowing blue eyes, forest floor setting, whimsical fantasy illustration, soft painterly style, circular portrait, highly detailed, 400x400 avatar</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/pebble.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>700 — Twig</h3>
<p><i>Young forest sprite.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>700</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>699 (-1)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>0%</td></tr></table>
<p><b>Prompt</b><br><sub>Tiny forest sprite made of twigs and leaves, bright curious eyes, woodland fantasy creature, painterly illustration, circular portrait, cozy nature game style</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/twig.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>800 — Mote</h3>
<p><i>Floating forest spirit.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>800</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>856 (+56)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>40%</td></tr></table>
<p><b>Prompt</b><br><sub>Small glowing nature spirit, floating seed-like creature, green and gold glow, magical forest atmosphere, whimsical fantasy character portrait</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/mote.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>850 — Hazel</h3>
<p><i>A dormouse curled around a hazelnut twice its size, sleepy-eyed, in a nest of gold leaves. The most harmless thing on the ladder that can still beat you.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>850</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>852 (+2)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>30%</td></tr></table>
<p><b>Prompt</b><br><sub>Tiny dormouse forest spirit hugging a hazelnut, sleepy golden eyes, nest of autumn leaves, warm honey and green palette, cozy woodland fantasy illustration, soft painterly style, circular portrait, highly detailed, 400x400 avatar</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/hazel.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>900 — Clover</h3>
<p><i>Lucky rabbit-like creature.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>900</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>950 (+50)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>23%</td></tr></table>
<p><b>Prompt</b><br><sub>Cute woodland animal spirit carrying a four-leaf clover, warm green palette, fantasy illustration, cozy game avatar, circular portrait</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/clover.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>940 — Sorrel</h3>
<p><i>A leggy young hare the colour of autumn bracken, ears too big for it, sitting in a patch of wood sorrel. Curious rather than brave.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>940</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>881 (-59)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork (5%)</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>21%</td></tr></table>
<p><b>Prompt</b><br><sub>Young russet hare spirit with oversized ears, sitting among wood sorrel and clover, warm amber and green palette, soft dappled forest light, whimsical fantasy illustration, soft painterly style, circular portrait, highly detailed, 400x400 avatar</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/sorrel.png" width="400">

</td>
</tr>
</table>


---

## Casual

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>980 — Bramble</h3>
<p><i>Hedgehog.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>980</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>994 (+14)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork (10%), denies a fork (3%)</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>19%</td></tr></table>
<p><b>Prompt</b><br><sub>Friendly hedgehog with berry-covered spines, forest guardian aesthetic, fantasy woodland illustration, cozy painterly avatar</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/bramble.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1020 — Juniper</h3>
<p><i>A young badger in a cloak of juniper needles, blue berries at the collar, striped face set in a frown. Small, and takes itself completely seriously.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1020</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>983 (-37)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork (16%), denies a fork (6%)</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>18%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 0.6</td></tr><tr><td width="26%" valign="top"><b>Consulted</b></td><td>9%</td></tr></table>
<p><b>Prompt</b><br><sub>Young badger forest guardian wearing a cloak of juniper needles and blue berries, striped face, determined expression, deep green and slate palette, woodland fantasy illustration, soft painterly style, circular portrait, highly detailed, 400x400 avatar</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/juniper.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1060 — Bracken</h3>
<p><i>A fern-frond creature, half plant and half beast, unfurling. Green on green, with the coiled crozier of a new fern for a tail.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1060</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1059 (-1)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork (24%), denies a fork (11%)</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>18%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 0.6</td></tr><tr><td width="26%" valign="top"><b>Consulted</b></td><td>16%</td></tr></table>
<p><b>Prompt</b><br><sub>Small woodland guardian made of unfurling fern fronds, coiled fiddlehead tail, mossy green palette, alert bright eyes, forest floor setting, whimsical fantasy illustration, soft painterly style, circular portrait, highly detailed, 400x400 avatar</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/bracken.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1100 — Willow</h3>
<p><i>Tree spirit.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1100</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1081 (-19)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork (33%), denies a fork (17%)</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>18%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 0.6</td></tr><tr><td width="26%" valign="top"><b>Consulted</b></td><td>26%</td></tr></table>
<p><b>Prompt</b><br><sub>Young willow tree spirit, leafy hair, glowing green eyes, magical woodland guardian, whimsical fantasy illustration</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/willow.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1140 — Rowan</h3>
<p><i>A rowan spirit in autumn, bark like weathered silver, a crown of red berries, holding a staff cut from its own branch. Where Willow is a season old, Rowan has seen a few.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1140</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1087 (-53)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork (43%), denies a fork (24%)</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>17%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 0.7, corner 0.5</td></tr><tr><td width="26%" valign="top"><b>Consulted</b></td><td>29%</td></tr></table>
<p><b>Prompt</b><br><sub>Autumn rowan tree spirit, weathered silver bark skin, crown of red rowan berries, carved branch staff, amber and crimson palette, standing in low golden light, magical woodland guardian, whimsical fantasy illustration, soft painterly style, circular portrait, highly detailed, 400x400 avatar</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/rowan.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1180 — Aspen</h3>
<p><i>An aspen spirit of white bark and coin-shaped leaves that never stop moving, pale and quick, the whole figure caught mid-shiver in the wind.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1180</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1196 (+16)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork (52%), denies a fork (31%)</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>16%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 0.7, corner 0.5</td></tr><tr><td width="26%" valign="top"><b>Consulted</b></td><td>36%</td></tr></table>
<p><b>Prompt</b><br><sub>Aspen tree spirit with white bark skin and trembling coin-shaped leaves, pale silver-green palette, hair and leaves streaming in wind, luminous quiet eyes, magical woodland guardian, whimsical fantasy illustration, soft painterly style, circular portrait, highly detailed, 400x400 avatar</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/aspen.png" width="400">

</td>
</tr>
</table>


---

## Club

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1220 — Vireo</h3>
<p><i>Songbird elder.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1220</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1187 (-33)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork (60%), denies a fork (38%)</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>16%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 0.7, corner 0.5</td></tr><tr><td width="26%" valign="top"><b>Consulted</b></td><td>44%</td></tr></table>
<p><b>Prompt</b><br><sub>Wise green vireo bird with ornamental feathers, forest sage aesthetic, painterly fantasy character portrait</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/vireo.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1260 — Finch</h3>
<p><i>Blue songbird.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1260</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1290 (+30)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork (64%), denies a fork (44%)</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>15%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 0.7, corner 0.5, building 0.05</td></tr><tr><td width="26%" valign="top"><b>Consulted</b></td><td>48%</td></tr></table>
<p><b>Prompt</b><br><sub>Small blue finch bird, intelligent eyes, perched on branch, fantasy nature illustration, detailed feathers, circular avatar</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/finch.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1300 — Kestrel</h3>
<p><i>Hunter bird.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1300</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1340 (+40)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork (74%), denies a fork (58%)</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>13%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 0.8, corner 0.6, building 0.1</td></tr><tr><td width="26%" valign="top"><b>Consulted</b></td><td>62%</td></tr></table>
<p><b>Prompt</b><br><sub>Noble kestrel hawk, sharp eyes, forest ranger look, warm brown feathers, fantasy portrait, painterly game avatar</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/kestrel.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1340 — Osprey</h3>
<p><i>A fish hawk, wings back, talons out, half a wingspan above dark water. It is literally the animal between Kestrel and Marlin, and the composition says so.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1340</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1385 (+45)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork (86%), denies a fork (78%)</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>11%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 0.9, corner 0.6, building 0.17</td></tr><tr><td width="26%" valign="top"><b>Consulted</b></td><td>80%</td></tr></table>
<p><b>Prompt</b><br><sub>Noble osprey fish hawk in a dive, white and dark brown plumage, talons extended over dark river water, spray and low mist, fierce amber eyes, forest river setting, fantasy portrait, painterly game avatar, circular portrait, highly detailed, 400x400 avatar</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/osprey.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1380 — Heron</h3>
<p><i>Grey-blue, motionless, standing in shallow water among reeds. Patience drawn as a threat — the opposite temperament to Kestrel and just as dangerous.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1380</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1502 (+122)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork (96%), denies a fork (94%)</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>8%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 1.0, corner 0.5, building 0.22</td></tr><tr><td width="26%" valign="top"><b>Consulted</b></td><td>93%</td></tr></table>
<p><b>Prompt</b><br><sub>Tall grey-blue heron spirit standing motionless in still reed water, sharp beak, unblinking pale eye, mist and dawn light, mirrored reflection, fantasy wildlife illustration, painterly game avatar, circular portrait, highly detailed, 400x400 avatar</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/heron.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1420 — Marlin</h3>
<p><i>River hunter.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1420</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1482 (+62)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork, denies a fork</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>7%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 1.0, corner 0.5, building 0.25</td></tr><tr><td width="26%" valign="top"><b>Consulted</b></td><td>97%</td></tr></table>
<p><b>Prompt</b><br><sub>Mystical marlin fish spirit emerging from water, blue and silver palette, fantasy illustration, detailed portrait</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/marlin.png" width="400">

</td>
</tr>
</table>


---

## Expert

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1460 — Lynx</h3>
<p><i>A forest lynx, tufted ears, frost still on its ruff, standing where the water ends and the woods begin. Warm greys and rust: the first warm coat on the ladder, one rung before the fire.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1460</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1444 (-16)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork, denies a fork</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>6%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 1.0, corner 0.5, building 0.25</td></tr><tr><td width="26%" valign="top"><b>Search</b></td><td>forcing search 2</td></tr></table>
<p><b>Prompt</b><br><sub>Powerful forest lynx spirit, tufted black ear tips, thick rust and grey ruff, frost melting on fur, standing at a riverbank at dusk, piercing golden eyes, elegant fantasy wildlife illustration, painterly game avatar, circular portrait, highly detailed, 400x400 avatar</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/lynx.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1500 — Sable</h3>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1500</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1480 (-20)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork, denies a fork</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>5%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 1.0, corner 0.5, building 0.25</td></tr><tr><td width="26%" valign="top"><b>Search</b></td><td>2-ply, forcing search 2</td></tr><tr><td width="26%" valign="top"><b>Temperament</b></td><td>aggression 0.6</td></tr></table>
<p><b>Prompt</b><br><sub>Elegant sable forest predator, sleek dark fur, magical silver markings, fantasy wildlife illustration</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/sable.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1540 — Ember</h3>
<p><i>Fox of fire.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1540</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1552 (+12)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork, denies a fork</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>4%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 1.0, corner 0.5, building 0.25</td></tr><tr><td width="26%" valign="top"><b>Search</b></td><td>3-ply, forcing search 3</td></tr><tr><td width="26%" valign="top"><b>Temperament</b></td><td>aggression 0.4</td></tr></table>
<p><b>Prompt</b><br><sub>Magical fox made of embers and leaves, glowing orange eyes, forest fire spirit, elegant fantasy portrait</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/ember.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1580 — Lyra</h3>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1580</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1570 (-10)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork, denies a fork</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>4%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 1.0, corner 0.5, building 0.25</td></tr><tr><td width="26%" valign="top"><b>Search</b></td><td>3-ply, forcing search 4</td></tr></table>
<p><b>Prompt</b><br><sub>Celestial owl spirit with constellation markings, glowing star patterns, magical night sky aesthetic, fantasy portrait</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/lyra.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1640 — Onyx</h3>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1640</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1650 (+10)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork, denies a fork</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>3%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 1.0, corner 0.5, building 0.25</td></tr><tr><td width="26%" valign="top"><b>Search</b></td><td>3-ply, forcing search 6</td></tr></table>
<p><b>Prompt</b><br><sub>Black crystal raven spirit, dark gemstone feathers, glowing violet eyes, mystical fantasy portrait</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/onyx.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1700 — Corvus</h3>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1700</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1775 (+75)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork, denies a fork</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>2%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 1.0, corner 0.5, building 0.25</td></tr><tr><td width="26%" valign="top"><b>Search</b></td><td>4-ply, forcing search 9</td></tr></table>
<p><b>Prompt</b><br><sub>Legendary raven king, ornate feather crown, deep blue-black plumage, mystical forest monarch, fantasy illustration</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/corvus.png" width="400">

</td>
</tr>
</table>


---

## Master

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1800 — Basalt</h3>
<p><i>Rock giant.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1800</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1712 (-88)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork, denies a fork</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>2%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 1.0, corner 0.5, building 0.25</td></tr><tr><td width="26%" valign="top"><b>Search</b></td><td>500,000 nodes, max depth 8, forcing search 9</td></tr></table>
<p><b>Prompt</b><br><sub>Ancient basalt stone golem with glowing crystal eyes, moss-covered armor, powerful nature guardian, painterly fantasy avatar</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/basalt.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>1900 — Cairn</h3>
<p><i>A sentinel of stacked stones held together by nothing visible, moss in the joints, rune-cut faces, each block hovering a hand&#x27;s width from the next. Still, where Basalt is massive.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>1900</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>1993 (+93)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork, denies a fork</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>1%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 1.0, corner 0.5, building 0.25</td></tr><tr><td width="26%" valign="top"><b>Search</b></td><td>900,000 nodes, max depth 8, forcing search 11, defensive search 5</td></tr></table>
<p><b>Prompt</b><br><sub>Guardian of stacked floating stones held apart by glowing runes, moss and lichen in the gaps, single carved eye-slit, cold grey and pale green palette, ancient forest clearing, powerful nature guardian, painterly fantasy avatar, circular portrait, highly detailed, 400x400 avatar</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/cairn.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>2000 — Flint</h3>
<p><i>Dark stone struck to a sharp edge, sparks caught along the fracture lines, the first glint of gemstone in a body that is still rock. Leads straight into Onyx.</i></p>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>2000</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>2094 (+94)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork, denies a fork</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>0%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 1.0, corner 0.5, building 0.25</td></tr><tr><td width="26%" valign="top"><b>Search</b></td><td>1,800,000 nodes, max depth 10, forcing search 13, defensive search 7</td></tr></table>
<p><b>Prompt</b><br><sub>Dark flint stone guardian with freshly fractured razor edges, orange sparks caught along the fracture lines, glowing amber core seen through cracks, charcoal and ember palette, ancient forest, powerful nature guardian, painterly fantasy avatar, circular portrait, highly detailed, 400x400 avatar</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/flint.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>2100 — Quartz</h3>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>2100</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>2135 (+35)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork, denies a fork</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>0%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 1.0, corner 0.5, building 0.25</td></tr><tr><td width="26%" valign="top"><b>Search</b></td><td>2,500,000 nodes, max depth 10, forcing search 15, defensive search 9, exact below 10 empties</td></tr></table>
<p><b>Prompt</b><br><sub>Crystal guardian made from quartz stone, luminous crystals, ancient magical protector, fantasy portrait</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/quartz.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>2200 — Titan</h3>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>2200</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>2065 (-135)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork, denies a fork</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>0%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 1.0, corner 0.5, building 0.25</td></tr><tr><td width="26%" valign="top"><b>Search</b></td><td>3,000,000 nodes, max depth 11, forcing search 17, defensive search 11, exact below 11 empties</td></tr></table>
<p><b>Prompt</b><br><sub>Massive ancient woodland titan, bark armor, crystal core, forest demigod, majestic fantasy character portrait</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/titan.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>2300 — Oracle</h3>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>2300</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>2224 (-76)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork, denies a fork</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>0%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 1.0, corner 0.5, building 0.25</td></tr><tr><td width="26%" valign="top"><b>Search</b></td><td>1,800,000 nodes, max depth 10, forcing search 13, defensive search 5, plays the book from move one, so it cannot be beaten when it opens</td></tr></table>
<p><b>Prompt</b><br><sub>Ancient nature oracle spirit, glowing runes, mystical crown of branches, wise forest deity, elegant fantasy illustration</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/oracle.png" width="400">

</td>
</tr>
</table>

<table width="100%">
<tr>
<td width="58%" valign="top">

<h3>2400 — Quadrim Prime</h3>
<table width="100%"><tr><td width="26%" valign="top"><b>Published</b></td><td>2400</td></tr><tr><td width="26%" valign="top"><b>Measured</b></td><td>2254 (-146)</td></tr><tr><td width="26%" valign="top"><b>Rules</b></td><td>takes a win, blocks a loss, builds a fork, denies a fork</td></tr><tr><td width="26%" valign="top"><b>Blunder rate</b></td><td>0%</td></tr><tr><td width="26%" valign="top"><b>Position</b></td><td>centre 1.0, corner 0.5, building 0.25</td></tr><tr><td width="26%" valign="top"><b>Search</b></td><td>3,000,000 nodes, max depth 12, forcing search 20, defensive search 9, exact below 12 empties, plays the book from move one, so it cannot be beaten when it opens</td></tr></table>
<p><b>Prompt</b><br><sub>Ultimate guardian of the forest realm, fusion of stone, crystal, roots and celestial energy, majestic glowing crown, legendary final boss portrait, premium fantasy game avatar, highly detailed, breathtaking painterly artwork</sub></p>

</td>
<td width="42%" valign="top" align="center">

<img src="designs/quadrim_prime.png" width="400">

</td>
</tr>
</table>

