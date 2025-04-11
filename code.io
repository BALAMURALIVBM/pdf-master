<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PDF Master</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap" rel="stylesheet">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf-lib/1.16.0/pdf-lib.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/tesseract.js/4.0.2/tesseract.min.js"></script>
    <style>
        :root {
            --bg-color: #e7d3b7;
            --text-color: #2e2e2e;
            --container-bg: #fff9f1;
            --button-bg: #8b5e3c;
            --button-hover: #6e462a;
            --modal-bg: rgba(0, 0, 0, 0.6);
        }
        [data-theme="dark"] {
            --bg-color: #2b1f14;
            --text-color: #f7f1e3;
            --container-bg: #3e2e21;
            --button-bg: #a87c4a;
            --button-hover: #8a6439;
        }

        body {
            font-family: 'Inter', sans-serif;
            background: var(--bg-color);
            color: var(--text-color);
            margin: 0;
            padding: 0;
            transition: background 0.5s, color 0.5s;
        }
        header {
            background-color: var(--button-bg);
            color: #ffffff;
            padding: 20px;
            text-align: center;
            font-size: 28px;
            font-weight: 600;
            position: relative;
        }
        .container {
            max-width: 500px;
            margin: 50px auto;
            background: var(--container-bg);
            padding: 40px;
            border-radius: 16px;
            box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15);
        }
        .container h2 {
            margin-bottom: 20px;
        }
        input[type="file"], button {
            width: 100%;
            padding: 14px;
            margin: 10px 0;
            font-size: 16px;
            border-radius: 8px;
            border: none;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }
        button {
            background-color: var(--button-bg);
            color: #ffffff;
            cursor: pointer;
            transition: background 0.3s ease, transform 0.2s;
        }
        button:hover {
            background-color: var(--button-hover);
            transform: scale(1.03);
        }
        .modal {
            display: none;
            position: fixed;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: var(--modal-bg);
            justify-content: center;
            align-items: center;
        }
        .modal-content {
            background: var(--container-bg);
            padding: 30px;
            border-radius: 10px;
            text-align: center;
            width: 80%;
            max-width: 500px;
        }
        #themeToggle {
            position: left ;
            top: 10px;
            right: 10px;
            background: transparent;
            color: white;
            font-size: 24px;
            border: none;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <header>
        PDF Master
        <button id="themeToggle">🌙</button>
    </header>
    <div class="container">
        <h2>Tools</h2>
        <input type="file" id="fileUpload" multiple accept="application/pdf,image/*">
        <button onclick="createPDF()">Make PDF</button>
        <button onclick="mergePDFs()">Merge PDFs</button>
        <button onclick="rotatePDF()">Rotate PDF</button>
        <button onclick="performOCR()">OCR Picture</button>
        <button onclick="compressPDF()">Compress PDF</button>
    </div>

    <div class="modal" id="ocrModal">
        <div class="modal-content">
            <h2>Extracted Text</h2>
            <p id="ocrResult"></p>
            <button onclick="closeModal()">Close</button>
        </div>
    </div>

    <script>
        document.getElementById("themeToggle").addEventListener("click", () => {
            const html = document.documentElement;
            const theme = html.getAttribute("data-theme") === "dark" ? "light" : "dark";
            html.setAttribute("data-theme", theme);
        });

        async function createPDF() {
            const fileInput = document.getElementById("fileUpload");
            if (fileInput.files.length === 0) {
                alert("Please upload image files to create a PDF.");
                return;
            }

            const { jsPDF } = window.jspdf;
            const doc = new jsPDF();

            for (let i = 0; i < fileInput.files.length; i++) {
                const file = fileInput.files[i];
                if (!file.type.startsWith("image/")) continue;

                const reader = new FileReader();

                await new Promise((resolve) => {
                    reader.onload = function (event) {
                        const img = new Image();
                        img.onload = function () {
                            const imgProps = doc.getImageProperties(img);
                            const pdfWidth = doc.internal.pageSize.getWidth();
                            const pdfHeight = (imgProps.height * pdfWidth) / imgProps.width;
                            doc.addImage(img, 'JPEG', 0, 0, pdfWidth, pdfHeight);
                            if (i < fileInput.files.length - 1) {
                                doc.addPage();
                            }
                            resolve();
                        };
                        img.src = event.target.result;
                    };
                    reader.readAsDataURL(file);
                });
            }
            doc.save("newPDF.pdf");
        }

        async function mergePDFs() {
            const fileInput = document.getElementById("fileUpload");
            if (fileInput.files.length < 2) {
                alert("Please upload at least two PDFs to merge.");
                return;
            }
            const pdfDoc = await PDFLib.PDFDocument.create();
            for (let file of fileInput.files) {
                if (!file.name.endsWith(".pdf")) continue;
                const arrayBuffer = await file.arrayBuffer();
                const donorPdf = await PDFLib.PDFDocument.load(arrayBuffer);
                const copiedPages = await pdfDoc.copyPages(donorPdf, donorPdf.getPageIndices());
                copiedPages.forEach(page => pdfDoc.addPage(page));
            }
            const pdfBytes = await pdfDoc.save();
            downloadPDF(pdfBytes, "merged.pdf");
        }

        async function rotatePDF() {
            const fileInput = document.getElementById("fileUpload");
            if (fileInput.files.length === 0) {
                alert("Please upload a PDF to rotate.");
                return;
            }
            const file = fileInput.files[0];
            if (!file.name.endsWith(".pdf")) {
                alert("Please upload a valid PDF file.");
                return;
            }

            const arrayBuffer = await file.arrayBuffer();
            const pdfDoc = await PDFLib.PDFDocument.load(arrayBuffer);
            const pages = pdfDoc.getPages();
            pages.forEach(page => {
                const currentRotation = page.getRotation().angle;
                page.setRotation(PDFLib.degrees((currentRotation + 90) % 360));
            });
            const pdfBytes = await pdfDoc.save();
            downloadPDF(pdfBytes, "rotated.pdf");
        }

        async function compressPDF() {
            const fileInput = document.getElementById("fileUpload");
            if (fileInput.files.length === 0) {
                alert("Please upload a PDF to compress.");
                return;
            }
            const file = fileInput.files[0];
            if (!file.name.endsWith(".pdf")) {
                alert("Please upload a valid PDF file.");
                return;
            }
            const arrayBuffer = await file.arrayBuffer();
            const pdfDoc = await PDFLib.PDFDocument.load(arrayBuffer);

            const newDoc = await PDFLib.PDFDocument.create();
            const pages = await newDoc.copyPages(pdfDoc, pdfDoc.getPageIndices());
            pages.forEach((page) => {
                page.setFontSize?.(10); // reduce font size if applicable
                newDoc.addPage(page);
            });

            const pdfBytes = await newDoc.save({ useObjectStreams: false });
            downloadPDF(pdfBytes, "compressed.pdf");
        }

        function downloadPDF(pdfBytes, filename) {
            const blob = new Blob([pdfBytes], { type: "application/pdf" });
            const link = document.createElement("a");
            link.href = URL.createObjectURL(blob);
            link.download = filename;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }

        function performOCR() {
            const fileInput = document.getElementById("fileUpload");
            if (fileInput.files.length === 0) {
                alert("Please upload an image for OCR.");
                return;
            }
            const file = fileInput.files[0];
            if (!file.type.startsWith("image/")) {
                alert("Please upload a valid image file.");
                return;
            }
            const reader = new FileReader();
            reader.onload = function (event) {
                Tesseract.recognize(event.target.result, 'eng', {
                    logger: m => console.log(m)
                }).then(({ data: { text } }) => {
                    document.getElementById("ocrResult").textContent = text;
                    document.getElementById("ocrModal").style.display = "flex";
                }).catch(error => {
                    alert("OCR failed: " + error.message);
                });
            };
            reader.readAsDataURL(file);
        }

        function closeModal() {
            document.getElementById("ocrModal").style.display = "none";
        }
    </script>
</body>
</html>
