"""Tests for app.services.edamam module."""

from unittest.mock import MagicMock, patch

import pytest

from app.services import edamam as edamam_service


class TestAnalyzeNutrition:
    """Tests for analyze_nutrition function."""

    @patch("app.services.edamam.httpx.post")
    def test_analyze_nutrition_basic(self, mock_post):
        """Test basic nutrition analysis."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "ingredients": [
                {
                    "parsed": [
                        {
                            "nutrients": {
                                "ENERC_KCAL": {"quantity": 300},
                                "PROCNT": {"quantity": 25},
                                "FAT": {"quantity": 10},
                                "CHOCDF": {"quantity": 30},
                                "FIBTG": {"quantity": 2},
                            }
                        }
                    ]
                }
            ]
        }
        mock_post.return_value = mock_response

        result = edamam_service.analyze_nutrition("Chicken 100g")

        assert result["calories"] == 300.0
        assert result["protein_g"] == 25.0
        assert result["fat_g"] == 10.0
        assert result["carbs_g"] == 30.0
        assert result["fiber_g"] == 2.0

    @patch("app.services.edamam.httpx.post")
    def test_analyze_nutrition_empty_text(self, mock_post):
        """Test analyzing empty text."""
        result = edamam_service.analyze_nutrition("")

        assert result["calories"] == 0
        assert result["protein_g"] == 0
        mock_post.assert_not_called()

    @patch("app.services.edamam.httpx.post")
    def test_analyze_nutrition_multiple_ingredients(self, mock_post):
        """Test analyzing multiple ingredients."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "ingredients": [
                {"parsed": [{"nutrients": {"ENERC_KCAL": {"quantity": 300}}}]},
                {"parsed": [{"nutrients": {"ENERC_KCAL": {"quantity": 150}}}]},
            ]
        }
        mock_post.return_value = mock_response

        result = edamam_service.analyze_nutrition("Chicken\nRice")
        assert result["calories"] == 450.0

    @patch("app.services.edamam.httpx.post")
    def test_analyze_nutrition_api_error(self, mock_post):
        """Test API error handling."""
        mock_response = MagicMock()
        mock_response.status_code = 401
        mock_post.return_value = mock_response

        with pytest.raises(Exception):
            edamam_service.analyze_nutrition("Chicken")
