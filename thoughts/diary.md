First I asked opus low effor to create a GDD using the following:

---
Create a gdd document for this game. The point of this game is to be a thin vertical slice of a game similar to HayDay or Stardew Valley. The game is a farming simulator. You view your 2d farm in a top
  down camera view, place down processing facilities, farm plots, and make deliveries to earn money. You open a shop menu in the bottom left that opens an overlay with multiple tabs for Farm Seeds, Animal
  Homes, Animals, and Production Buildings. The goal is to just live on your farm and make more and more money. For now you can buy seeds (corn seed, wheat seeds, soybean seeds, potato seeds), buy a farm
  plot (max 25), buy a chicken coop (limit 1), buy a cow pasture (limit 1), dairy barn (limit 1), bakery (limit 1), feed mill (limit 1). The player starts with a player home and barn storage and silo storage
  (for plant stuff). Barn storage is everything else. The player can also buy axes and saws which can chop down trees that exist in their farm. The trees on their farm just serve as blockers which block the
  player from placing all the buildings or farm plots they want. they must first destroy these blockers by buying these tools and then using the tool on the blocker.
---

It asked me some questions and I said:

---
Can you make a recommendation for all those open questions?
---

Created an art catalog skill to be a reusable way for LLMs to quickly navigate these giant asset packs. Previously had issues where LLMs didn't really utilize asset packs I provided. Was a lot of back and forth planning with fable.

---

I asked agy:
> Create a visualization for how a 2D cozy farming game would look like. Visually like an rts camera angle and control.

then:
> Let's make another image that is similar to the 2nd image, RTS Building Placement & Grid Overlay. There should be no hud elements in the top except the setting cog in the top right. There should be no hud elements on the bottom except in the bottom left there is a button with the shop icon. When placing a building there should be no grid or green indicator on where you can place it except directly underneath the building being placed. There should also be no people and no lake or river.

then I added the storybook illustration, had claude redo all the references to pixel art.

---

Asking claude to ask agy to create art assets.

> Use agy to create the art assets we need that are listed in
@design/art-todo.md and export these art assets to /SourceArt. The
cozy_farm_visualization.jpg is a good visual indicator of what I want
except we don't have a green house and we should have the art be cut up
into different sprites. For example, the house, chicken coop, and barn
should be separate sprites so the player can place them not all one big
sprite. Look to C:\GameDev\cosmic-agent-tools\workshop for how to green
screen and interact with agy. I want you to use all 3 keying styles
(ffmpeg, built-in, corridorKey) so I can evaluate which of the 3 green
screen keyed files are the best if the sprite needs a transparent
> background. Keep going until we have all art assets created.

---

I hit the usage limit after generating 16 images. Switched to just using FFmpeg for green screening.

---

I only liked the cow/chicken art generally. So I had to redo all the art with manual green screening.

> Fix up the game to use the new art assets and stop using the deleted art assets. The main background should be empty_farm_landscape.png. The roads are just built in to the background not a separate image. Use house 2 for the player house. There is now different crops: wheat, beets, and cabbage. All share the same planted version with 2 variations that should be picked randomly on planting. They do not have an intermediate phase so remove that. And there is a new setting and shop button.

---
