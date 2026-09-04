<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" encoding="UTF-8" indent="yes"/>

  <xsl:template match="/">
    <html lang="en">
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title>Library Catalog</title>
        <link rel="stylesheet" href="estilo.css"/>
      </head>
      <body>
        <div class="catalog-shell">
          <header class="catalog-header">
            <div class="eyebrow">Online catalog</div>
            <h1>Library Collection</h1>
            <p>Professional digital showcase of our literary catalog, featuring detailed information and cover artwork for each title.</p>
          </header>

          <main class="books-grid">
            <xsl:for-each select="library/catalog/books/book">
              <article class="book-card">
                <div class="book-visual">
                  <img src="{images/image/path}" alt="{title}"/>
                </div>

                <div class="book-details">
                  <span class="badge">
                    <xsl:value-of select="format"/>
                  </span>

                  <h2>
                    <xsl:value-of select="title"/>
                  </h2>

                  <p class="author">
                    <xsl:value-of select="author"/>
                  </p>

                  <div class="stats">
                    <span>
                      <strong>ISBN</strong><br/>
                      <xsl:value-of select="isbn"/>
                    </span>
                    <span>
                      <strong>Year</strong><br/>
                      <xsl:value-of select="publicationYear"/>
                    </span>
                    <span>
                      <strong>Price</strong><br/>
                      $<xsl:value-of select="price"/>
                    </span>
                    <span>
                      <strong>Stock</strong><br/>
                      <xsl:value-of select="stock"/>
                    </span>
                  </div>

                  <div class="genre-list">
                    <xsl:for-each select="genres/genre">
                      <span class="genre-pill">
                        <xsl:value-of select="."/>
                      </span>
                    </xsl:for-each>
                  </div>

                  <div class="concepts">
                    <h3>Concepts</h3>
                    <ul>
                      <xsl:for-each select="concepts/concept">
                        <li>
                          <strong><xsl:value-of select="term"/>:</strong>
                          <xsl:text> </xsl:text>
                          <xsl:value-of select="definition"/>
                        </li>
                      </xsl:for-each>
                    </ul>
                  </div>
                </div>
              </article>
            </xsl:for-each>
          </main>
        </div>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
