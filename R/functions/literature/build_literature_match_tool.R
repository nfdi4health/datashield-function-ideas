# The tool of the idea check's literature match
# (prompts/idea-literature-prompt.md): which of the listed methods of the
# literature watch, if any, is the one a hub issue asks for.
build_literature_match_tool <- function() {
  s <- function(d) list(type = "string", description = d)
  list(
    description = "The literature watch's method closest to the issue's method.",
    input_schema = list(
      type = "object",
      properties = list(
        key = s("The key of the listed method that matches, or an empty string if none does."),
        variant = s("The key of one of that method's listed variants if the issue asks for exactly that variant, else an empty string."),
        relation = list(type = "string", enum = list("same", "broader", "narrower", "none"),
          description = "same: the same method; broader: the listed method includes the issue's method and more; narrower: the listed method is one part or case of it; none: no listed method fits."),
        note = s("One short sentence on the difference, if any.")
      ),
      required = list("key", "variant", "relation", "note"),
      additionalProperties = FALSE
    )
  )
}
