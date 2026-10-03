package mesh.crypto;

public class EncryptedPayload {
    public String iv;
    public String ciphertext;
    public String wrappedKey;

    public String toJson() {
        return "{\"iv\":\"" + iv + "\",\"ciphertext\":\"" + ciphertext + "\",\"wrappedKey\":\"" + wrappedKey + "\"}";
    }

    public static EncryptedPayload fromJson(String json) {
        EncryptedPayload p = new EncryptedPayload();
        p.iv = extract(json, "iv");
        p.ciphertext = extract(json, "ciphertext");
        p.wrappedKey = extract(json, "wrappedKey");
        return p;
    }

    public static String extract(String json, String key) {
        String marker = "\"" + key + "\":\"";
        int start = json.indexOf(marker);
        if (start == -1) return "";
        start += marker.length();
        int end = json.indexOf("\"", start);
        return json.substring(start, end);
    }
}