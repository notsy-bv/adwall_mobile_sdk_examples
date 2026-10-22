package media.membrana.adwall.demo.compose

/** App-owned content, matching the iOS customer examples. */
object DemoArticle {
    const val category = "DEMO"
    const val title = "The article that opens before its locked tail"
    const val summary = "A five-part story demonstrating an open introduction followed by protected content through the end."
    val paragraphs = listOf(
        "The first paragraph is open to everyone. It establishes the story and gives readers enough context to decide whether they want to continue.",
        "The second paragraph begins the protected chapter. This section is covered by MembranaAdWall until the reader chooses to watch the rewarded message.",
        "The third paragraph remains part of that protected chapter, preserving a meaningful block of premium content rather than hiding a single sentence.",
        "The fourth paragraph remains protected. Access is granted only after completing the rewarded ad.",
        "The fifth and final paragraph is protected as well, demonstrating that the wall covers the article from the selected gate point to the end.",
    )
}
