import os

from flask import Flask, request, jsonify

app = Flask(__name__)

# @Gemini: keep this route and function as-is
@app.route("/ping")
def hello_world():
    """Example Ping route"""
    resp = os.environ.get("RESP", "pong")
    return f"{resp}"


# @Gemini: modify this route and function depending on the context of the notebook
@app.route('/submit', methods=['POST'])
def submit():

    if 'image' not in request.files:
        return jsonify({'error': 'No image part'}), 400

    image = request.files['image']

    if image.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    if 'text' not in request.form:
        return jsonify({'error': 'No text part'}), 400

    text = request.form['text']

    if image and text:
        filename = os.path.join(app.config['UPLOAD_FOLDER'], image.filename)
        image.save(filename)

        # Further processing of image and text
        # ... your code to process image (e.g., using OpenCV) and text ...
        # For example:
        # processed_image = process_image(filename)
        # result = analyze_data(processed_image, text)

        return jsonify({'message': 'Image and text processed successfully'}), 200



if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))