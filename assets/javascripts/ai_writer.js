// SPDX-FileCopyrightText: 2024 Tuan Anh
// SPDX-License-Identifier: MIT

// Encapsulate the AI Writer logic in a single object to avoid polluting the global namespace.
const AIWriter = {
  // Store configuration passed from the Rails view
  config: {},

  // DOM elements
  elements: {},

  /**
   * Initializes the AI Writer functionality.
   * @param {object} config - Configuration passed from the Rails view.
   */
  init(config) {
    this.config = config;
    this.cacheDOMElements();
    this.addEventListeners();
  },

  /**
   * Caches frequently used DOM elements to avoid repeated lookups.
   */
  cacheDOMElements() {
    this.elements.button = document.getElementById(this.config.buttonId);
    this.elements.resultContainer = document.getElementById(this.config.resultContainerId);
    this.elements.promptField = document.getElementById(this.config.promptFieldId);
    this.elements.pageTitle = document.querySelector(this.config.pageTitleSelector);
  },

  /**
   * Adds event listeners to the interactive elements.
   */
  addEventListeners() {
    if (this.elements.button) {
      this.elements.button.addEventListener('click', this.handleGenerateClick.bind(this));
    }
  },

  /**
   * Handles the 'Generate Content' button click event.
   */
  async handleGenerateClick() {
    if (!this.validateInputs()) return;

    this.setButtonState('loading');
    this.elements.resultContainer.style.display = 'none';
    this.elements.resultContainer.innerHTML = '';

    try {
      const response = await fetch(this.config.generateUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': this.config.csrfToken },
        body: JSON.stringify({
          issue_title: this.elements.pageTitle.innerText.trim(),
          user_prompt: this.elements.promptField.value.trim(),
        }),
      });

      const data = await response.json();
      if (!response.ok) throw new Error(data.error || 'Unknown error occurred.');
      
      this.displayResult(data.content, data.content_id);

    } catch (error) {
      console.error('AI Writer Error:', error);
      alert(`Error generating content: ${error.message}`);
    } finally {
      this.setButtonState('idle');
    }
  },

  /**
   * Validates that the necessary input fields exist and have values.
   * @returns {boolean} - True if inputs are valid, otherwise false.
   */
  validateInputs() {
    if (!this.elements.promptField) {
      alert(`Prompt custom field not found.`);
      return false;
    }
    if (this.elements.promptField.value.trim() === '') {
      alert('Please enter a prompt.');
      return false;
    }
    return true;
  },

  displayResult(content, contentId, isEditing = false) {
    let contentHtml;
    let buttonsHtml;

    if (isEditing) {
      contentHtml = `<textarea id="ai-writer-edit-area" class="wiki-edit" rows="15" style="width: 100%;">${content}</textarea>`;
      buttonsHtml = `
        <button type="button" class="button" id="ai-writer-save-btn">${this.config.text.save}</button>
      `;
    } else {
      contentHtml = `<div class="wiki"><p>${content.replace(/\n/g, '<br>')}</p></div>`;
      buttonsHtml = `
        <button type="button" class="button" id="ai-writer-agree-btn">${this.config.text.agree}</button>
        <button type="button" class="button" id="ai-writer-retry-btn">${this.config.text.retry}</button>
        <button type="button" class="button" id="ai-writer-edit-btn">${this.config.text.edit}</button>
      `;
    }

    this.elements.resultContainer.innerHTML = `${contentHtml}<p class="buttons">${buttonsHtml}</p>`;
    this.elements.resultContainer.style.display = 'block';

    if (isEditing) {
      document.getElementById('ai-writer-save-btn').addEventListener('click', () => this.handleSaveClick(contentId));
    } else {
      document.getElementById('ai-writer-agree-btn').addEventListener('click', () => this.handleAgreeClick(contentId));
      document.getElementById('ai-writer-retry-btn').addEventListener('click', this.handleRetryClick.bind(this));
      document.getElementById('ai-writer-edit-btn').addEventListener('click', () => this.handleEditClick(content, contentId));
    }
  },

  handleEditClick(content, contentId) {
    this.displayResult(content, contentId, true);
  },

  async handleSaveClick(contentId) {
    const editArea = document.getElementById('ai-writer-edit-area');
    const newContent = editArea.value;
    const saveButton = document.getElementById('ai-writer-save-btn');
    saveButton.disabled = true;

    try {
      const response = await fetch(this.config.updateUrlTemplate.replace('CONTENT_ID_PLACEHOLDER', contentId), {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': this.config.csrfToken },
        body: JSON.stringify({ content: newContent }),
      });
      const data = await response.json();
      if (!data.success) throw new Error(data.error || 'Failed to save content.');
      
      this.displayResult(newContent, contentId, false);

    } catch (error) {
      console.error('AI Writer Save Error:', error);
      alert(`Error saving content: ${error.message}`);
      saveButton.disabled = false;
    }
  },

  async handleAgreeClick(contentId) {
    document.getElementById('ai-writer-agree-btn').disabled = true;
    try {
      const response = await fetch(this.config.applyUrlTemplate.replace('CONTENT_ID_PLACEHOLDER', contentId), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': this.config.csrfToken },
      });
      const data = await response.json();
      if (!data.success) throw new Error(data.error || 'Failed to apply content.');
      
      window.location.reload();

    } catch (error) {
      console.error('AI Writer Apply Error:', error);
      alert(`Error applying content: ${error.message}`);
      document.getElementById('ai-writer-agree-btn').disabled = false;
    }
  },
  
  handleRetryClick() {
    const editButton = document.querySelector('div.contextual a.icon-edit');
    if (editButton) editButton.click();
    else alert('Could not find the main "Edit" button.');
  },

  /**
   * Manages the button's state (text and disabled status).
   * @param {'loading' | 'idle'} state - The desired state.
   */
  setButtonState(state) {
    if (!this.elements.button) return;
    this.elements.button.disabled = (state === 'loading');
    this.elements.button.innerText = (state === 'loading') ? this.config.text.generating : this.config.text.generateContent;
  },

  waitForElement(selector, timeout = 5000) {
    return new Promise((resolve, reject) => {
      const interval = 100;
      let time = 0;

      const poller = setInterval(() => {
        const element = document.querySelector(selector);
        if (element) {
          clearInterval(poller);
          resolve(element);
        } else {
          time += interval;
          if (time >= timeout) {
            clearInterval(poller);
            reject(new Error(`Element "${selector}" not found after ${timeout / 1000}s.`));
          }
        }
      }, interval);
    });
  }
}; 
