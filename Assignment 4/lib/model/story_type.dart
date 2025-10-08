enum StoryType {
  top('Top Stories', 'topstories'),
  best('Best Stories', 'beststories'),
  newStories('New Stories', 'newstories');

  const StoryType(this.displayName, this.apiEndpoint);

  final String displayName;
  final String apiEndpoint;
}