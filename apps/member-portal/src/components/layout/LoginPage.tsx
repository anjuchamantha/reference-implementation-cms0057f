// src/pages/LoginPage.js
import { useState } from "react";
import {
  Button,
  Typography,
  Box,
  Container,
  Paper,
  FormControl,
} from "@mui/material";
import { useNavigate } from "react-router-dom";
import apiClient from "../../services/apiClient";
import React from "react";
import { ORGANIZATION_SERVICE_URL } from "../../configs/Constants";

const LoginPage = () => {
  const [memberId, setMemberId] = useState("");
  const [userName, setUserName] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const navigate = useNavigate(); // Initialize navigate hook

  const handleLogin = (e: { preventDefault: () => void }) => {
    e.preventDefault();

    if (!memberId || !password) {
      setError("Please enter both ID and password");
      return;
    }

    // Simulate an API call that returns a 200 status
    apiClient(ORGANIZATION_SERVICE_URL)
      .post("/member/login", {
        memberId: memberId,
        password: password,
        name: "",
      })
      .then((response) => {
        console.log(response);
        if (response.status === 201) {
          console.log("Login successful:", { memberId: memberId, password });
          setError("");
          // Redirect to /home upon successful login
          navigate("/dashboard", { state: { userName, memberId } });
        } else {
          setError("Login failed. Please check your credentials)");
        }
      })
      .catch((error) => {
        console.error("Error:", error);
        setError("Login failed. Please check your credentials");
      });
  };

  return (
    <Container maxWidth="lg">
      <Box display="flex" height="100vh">
        {/* Left 2/3 section - Text Area */}
        <Box
          flex={2}
          display="flex"
          justifyContent="center"
          alignItems="center"
          p={4}
          sx={{ backgroundColor: "background.paper" }}
        >
          <Box display={"row"}>
            <Typography variant="h2" align="center" padding={4}>
              USPayer Member Portal
            </Typography>
            <Typography variant="h6" align="center">
              This website serves as an interactive platform showcasing
              real-world use cases of the DaVinci Payer Data Exchange
              implementation guide, a crucial initiative aimed at streamlining
              healthcare data sharing between payers, providers, and other
              stakeholders. With a focus on interoperability, this site
              demonstrates how DaVinci standards enable seamless, secure, and
              efficient exchange of clinical and administrative data.
            </Typography>
          </Box>
        </Box>

        <Box
          flex={1}
          display="flex"
          justifyContent="center"
          alignItems="center"
          p={4}
          sx={{ backgroundColor: "#fff" }}
        >
          <Paper
            elevation={3}
            sx={{ p: 4, width: "100%", maxWidth: "400px", borderRadius: "8px" }}
          >
            <Typography variant="h5" align="center" mb={3}>
              Welcome to the Member Portal
            </Typography>

            <Box component="form" onSubmit={handleLogin}>
              <FormControl fullWidth>
                <Button
                  type="submit"
                  variant="contained"
                  fullWidth
                  sx={{ mt: 3, mb: 2 }}
                  onClick={() => {
                    window.location.href = "/auth/login";
                  }}
                >
                  Login
                </Button>
              </FormControl>
            </Box>
          </Paper>
        </Box>
      </Box>
    </Container>
  );
};

export default LoginPage;
