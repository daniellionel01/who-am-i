# 🥸 Who am I?

This was generated with GPT 5 with the following prompt:

## Prompt

Code a website to play "who am I?" in a group of people. Given a list of participants everyone chooses an identiy for them and then take turns guess who they are.
The website is only there to provide a list for everyone so that they know who everyone else's identity is. Their own is never revealed to them, since they
have to guess it in real life.

The website works purely client side and stores state in the URL. No server or database is required.

We're using only HTML, CSS and JavaScript. No frameworks, so no tailwind and no react. Only vanilla CSS and vanilla JavaScript. Everything will be on one page and in one file.
There are no multiple routes. Just one route where everything happens.

Here is how a user will experience the page:

Initially you see an option to create a new game by providing your name. You will be the first one to join the game.
After providing your name you are given the option to add more participants for who you can enter their name.

The one responsible for choosing the identity for one person (which they discuss in real life) will be given the device with the website open and they can click on a button
next to the person which opens a dialog where they can enter the identity for that person, which will be stored in the state. That identiy does not appear next to the person though
and is only stored in the background since they should not accidentally see their own identity.

Once all identities are assigned we can enter a screen where you see the identity of everyone except your own which is blurred / blank.

Since we want the others to also see this list the one creating the game can share the game for others to join. They can click a button which copies the link for the others to join
to the clipboard and also provides a qrcode that they can scan.

Once the others visit that page they first have to choose who of the people they are so that we can hide / blur that identity in the list that they see. But they can see everyone
else's identity.

Additional Features:
- At every point you should have the ability to make a "new game" that prompts if they want to exit the current game. This should clear the state and put them into a new game screen.

Few technical points:
- Keep things simple. For example you dont have to create your own fancy modal logic. You're allowed to use the browser built-in `prompt` and `confirm` functions.
