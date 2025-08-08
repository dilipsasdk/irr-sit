public  class IRR_MOD_ShortenURL {

    public List<ShortURL> shortenedUrls { get; set; }
    public class ShortURL {
        public String originalUrl { get; set; }
        public String shortenedUrl { get; set; }
      }
}