import { test } from "node:test";
import assert from "node:assert/strict";
import { blockedTitle, sessionTitle } from "./title.ts";

test("sessionTitle names the app and the working directory", () => {
  assert.equal(sessionTitle(undefined, "/Users/endoze/.dotfiles"), "π - .dotfiles");
});

test("sessionTitle includes the session name when there is one", () => {
  assert.equal(
    sessionTitle("widget work", "/Users/endoze/.dotfiles"),
    "π - widget work - .dotfiles",
  );
});

test("sessionTitle ignores a trailing separator", () => {
  assert.equal(sessionTitle(undefined, "/Users/endoze/.dotfiles/"), "π - .dotfiles");
});

test("blockedTitle appends the marker herdr watches for", () => {
  assert.equal(
    blockedTitle(undefined, "/Users/endoze/.dotfiles"),
    "π - .dotfiles [Action Required]",
  );
});

test("blockedTitle keeps the session name", () => {
  assert.equal(
    blockedTitle("widget work", "/Users/endoze/.dotfiles"),
    "π - widget work - .dotfiles [Action Required]",
  );
});
