{ config, ... }:
let
  inherit (config.meta) pages;
  otherPages = builtins.attrValues (builtins.removeAttrs pages [ "options" ]);
  hasPage = opt: builtins.any (page: builtins.elem opt page.options) otherPages;
in
{
  # This page is responsible for all options not owned by another page
  meta.pages.options = {
    optionPredicate = opt: !hasPage opt;
  };

  # TODO: add an assertion that options are not owned by multiple pages
  # This should not use the `assertions` option to avoid evaluating the entire option set in normal module evals
  # Maybe the docs could have their own assertions module?
}
