import React from 'react'
import ReactDOM from 'react-dom/client'
import App from '@/App'
import '@/index.css'

/**
 * Vite entry point - Initialize React 18 application
 *
 * Sets up the React application root using React 18's createRoot API.
 * Wraps the application in StrictMode for additional development checks
 * including detecting unexpected side effects and deprecated API usage.
 *
 * @throws {Error} If root element with id="root" is not found in the DOM
 */
const rootElement = document.getElementById('root')

if (!rootElement) {
  throw new Error('Root element with id="root" not found in HTML')
}

ReactDOM.createRoot(rootElement).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
)
